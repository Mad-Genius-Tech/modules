"""Exercise SNS delivery at the Lambda handler and its HTTP boundary."""

import importlib.util
import json
import os
from pathlib import Path
import socket
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError


ADAPTER = Path(os.getenv("SNS_ADAPTER_PATH", Path(__file__).parents[1] / "slack/functions/app.py"))
WEBHOOK = "https://hooks.slack.com/services/TTEST/BTEST/repair-test"


def event(*messages):
    return {"Records": [{"EventSource": "aws:sns", "Sns": {
        "Subject": "AWS repair test", "Message": message,
    }} for message in messages]}


class Response:
    status = 200

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def read(self, limit):
        return b"ok"


class SlackDeliveryTests(unittest.TestCase):
    def setUp(self):
        environment = patch.dict(os.environ, {"WEBHOOK_URL": WEBHOOK, "MESSENGER": "slack"})
        environment.start()
        self.addCleanup(environment.stop)
        spec = importlib.util.spec_from_file_location("slack_adapter", ADAPTER)
        self.app = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.app)

    def deliver(self, payload):
        with patch.dict(os.environ, {"WEBHOOK_URL": WEBHOOK}), patch.object(
            self.app, "urlopen", return_value=Response()
        ) as send:
            result = self.app.lambda_handler(payload, None)
            bodies = [json.loads(call.args[0].data) for call in send.call_args_list]
            self.assertTrue(all(call.kwargs["timeout"] == 5 for call in send.call_args_list))
            return result, bodies

    def test_plain_sns_message_is_a_valid_slack_payload(self):
        result, bodies = self.deliver(event("3 pending RDS maintenance actions"))
        self.assertEqual(result, {"delivered": 1})
        self.assertIn("3 pending RDS maintenance actions", bodies[0]["text"])
        self.assertFalse(bodies[0]["mrkdwn"])

    def test_cloudwatch_alarm_retains_its_diagnostic_fields(self):
        alarm = {"AlarmName": "test-alarm", "NewStateValue": "ALARM", "NewStateReason": "Task missing"}
        _, bodies = self.deliver(event(json.dumps(alarm)))
        for value in alarm.values():
            self.assertIn(value, bodies[0]["text"])

    def test_cloudwatch_alarm_renders_a_readable_card_without_interpreting_mentions(self):
        alarm = {"AlarmName": "mgb-dev-fabric-dao-task-failure", "NewStateValue": "ALARM",
                 "NewStateReason": "Task stopped <@U123>", "AlarmDescription": "Inspect task logs",
                 "StateChangeTime": "2026-10-08T16:37:14Z", "Region": "US West (Oregon)"}
        _, bodies = self.deliver(event(json.dumps(alarm)))
        card = bodies[0]["blocks"]
        self.assertEqual(card[0]["text"], {"type": "plain_text", "text": "ALARM: mgb-dev-fabric-dao-task-failure"})
        self.assertEqual(card[1]["text"], {"type": "plain_text", "text": "Task stopped <@U123>"})
        self.assertTrue(all(block["text"]["type"] == "plain_text" for block in card if "text" in block))
        self.assertIn("2026-10-08T16:37:14Z", json.dumps(card))
        self.assertIn("Inspect task logs", json.dumps(card))
        self.assertIn(json.dumps(alarm), bodies[0]["text"])

    def test_task_failure_ok_card_does_not_claim_service_recovery(self):
        alarm = {"AlarmName": "mgb-dev-fabric-dao-task-failure", "NewStateValue": "OK",
                 "NewStateReason": "No datapoints in 15 periods", "Trigger": {"Namespace": "AWS/Events", "MetricName": "TriggeredRules"}}
        _, bodies = self.deliver(event(json.dumps(alarm)))
        self.assertIn("No recent matching failures; service recovery is not verified.", json.dumps(bodies[0]["blocks"]))

    def test_ecs_event_retains_failure_reason_and_resource(self):
        failure = {"source": "aws.ecs", "detail-type": "ECS Deployment State Change",
                   "detail": {"reason": "deployment failed", "deploymentId": "ecs-svc/test"}}
        _, bodies = self.deliver(event(json.dumps(failure)))
        self.assertIn("deployment failed", bodies[0]["text"])
        self.assertIn("ecs-svc/test", bodies[0]["text"])

    def test_every_record_is_delivered(self):
        result, bodies = self.deliver(event("first", "second"))
        self.assertEqual(result, {"delivered": 2})
        self.assertEqual(len(bodies), 2)

    def test_long_message_is_split_without_losing_the_failure_reason(self):
        message = "x" * 4500 + "FINAL FAILURE REASON"
        _, bodies = self.deliver(event(message))
        self.assertTrue(all(len(body["text"]) <= 3900 for body in bodies))
        self.assertIn(message, "".join(body["text"] for body in bodies))

    def test_invalid_event_fails_before_any_post(self):
        for payload in ({}, event(), {"Records": [None]}, {"Records": [{"EventSource": "aws:s3"}]}, event(123)):
            with self.subTest(payload=payload), patch.object(self.app, "urlopen") as send:
                with self.assertRaises(ValueError):
                    self.app.lambda_handler(payload, None)
                send.assert_not_called()

    def test_invalid_later_record_does_not_partially_deliver(self):
        payload = event("first", 123)
        with patch.object(self.app, "urlopen") as send:
            with self.assertRaises(ValueError):
                self.app.lambda_handler(payload, None)
            send.assert_not_called()

    def test_non_slack_webhook_fails_before_any_post(self):
        with patch.dict(os.environ, {"WEBHOOK_URL": "https://example.com/services/test"}), patch.object(
            self.app, "urlopen"
        ) as send:
            with self.assertRaises(ValueError):
                self.app.lambda_handler(event("test"), None)
            send.assert_not_called()

    def test_delivery_failure_raises_without_exposing_webhook(self):
        errors = [HTTPError(WEBHOOK, 403, "denied", {}, None),
                  URLError(WEBHOOK), socket.timeout(WEBHOOK)]
        for error in errors:
            with self.subTest(error=type(error).__name__), patch.dict(os.environ, {"WEBHOOK_URL": WEBHOOK}), patch.object(
                self.app, "urlopen", side_effect=error
            ):
                with self.assertRaises(RuntimeError) as raised:
                    self.app.lambda_handler(event("test"), None)
                self.assertNotIn(WEBHOOK, str(raised.exception))
                self.assertTrue(raised.exception.__suppress_context__)

    def test_http_success_with_slack_rejection_is_not_success(self):
        class Rejection(Response):
            def read(self, limit):
                return b"invalid_payload"
        with patch.dict(os.environ, {"WEBHOOK_URL": WEBHOOK}), patch.object(
            self.app, "urlopen", return_value=Rejection()
        ):
            with self.assertRaises(RuntimeError):
                self.app.lambda_handler(event("test"), None)


if __name__ == "__main__":
    unittest.main()
