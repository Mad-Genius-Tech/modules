"""Forward SNS notifications to Slack without an SDK layer or HTTP dependency."""

import json
import os
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


def alarm_card(message):
    """Show known CloudWatch alarms as plain-text blocks; retain the SNS fallback."""
    try:
        alarm = json.loads(message)
    except (ValueError, TypeError):
        return None
    if not isinstance(alarm, dict):
        return None
    name, state = alarm.get("AlarmName"), alarm.get("NewStateValue")
    if not isinstance(name, str) or not name or state not in ("ALARM", "OK", "INSUFFICIENT_DATA"):
        return None
    blocks = [{"type": "header", "text": {"type": "plain_text", "text": f"{state}: {name}"[:150]}}]
    for key in ("NewStateReason", "AlarmDescription"):
        value = alarm.get(key)
        if isinstance(value, str) and value:
            blocks.append({"type": "section", "text": {"type": "plain_text", "text": value[:3000]}})
    trigger = alarm.get("Trigger")
    if (state == "OK" and name.endswith("-task-failure") and isinstance(trigger, dict)
            and trigger.get("Namespace") == "AWS/Events" and trigger.get("MetricName") == "TriggeredRules"):
        blocks.append({"type": "section", "text": {"type": "plain_text",
                       "text": "No recent matching failures; service recovery is not verified."}})
    fields = []
    for label, key in (("Region", "Region"), ("Changed at", "StateChangeTime")):
        value = alarm.get(key)
        if isinstance(value, str) and value:
            fields.append({"type": "plain_text", "text": f"{label}: {value}"[:2000]})
    if fields:
        blocks.append({"type": "section", "fields": fields})
    return blocks


def lambda_handler(event, context):
    webhook = os.environ.get("WEBHOOK_URL", "")
    try:
        endpoint = urlsplit(webhook)
        valid = (endpoint.scheme == "https" and endpoint.hostname == "hooks.slack.com"
                 and endpoint.port in (None, 443) and endpoint.username is None
                 and endpoint.password is None and endpoint.path.startswith("/services/")
                 and not endpoint.query and not endpoint.fragment)
    except ValueError:
        valid = False
    if not valid:
        raise ValueError("A valid HTTPS Slack incoming webhook is required")

    records = event.get("Records") if isinstance(event, dict) else None
    if not isinstance(records, list) or not records:
        raise ValueError("At least one SNS record is required")

    messages = []
    for record in records:
        sns = record.get("Sns") if isinstance(record, dict) else None
        if not isinstance(record, dict) or record.get("EventSource") != "aws:sns" or not isinstance(sns, dict):
            raise ValueError("Only SNS notifications are supported")
        message = sns.get("Message")
        if not isinstance(message, str) or not message.strip():
            raise ValueError("SNS Message must be nonempty text")
        subject = sns.get("Subject") or "AWS SNS notification"
        if not isinstance(subject, str):
            raise ValueError("SNS Subject must be text")
        # Plain text preserves every AWS diagnostic field without interpreting
        # notification text as Slack markup, mentions, or another provider's API.
        messages.append((f"{subject}\n{message}", alarm_card(message)))

    for message, card in messages:
        for offset in range(0, len(message), 3900):
            payload = {"text": message[offset:offset + 3900], "mrkdwn": False}
            if card and offset == 0:
                payload["blocks"] = card
            request = Request(webhook, json.dumps(payload).encode("utf-8"),
                              {"Content-Type": "application/json"}, method="POST")
            try:
                with urlopen(request, timeout=5) as response:
                    accepted = response.status == 200 and response.read(256).strip() == b"ok"
            except HTTPError as error:
                raise RuntimeError(f"Slack rejected notification (HTTP {error.code})") from None
            except (URLError, OSError):
                raise RuntimeError("Slack delivery failed (network error)") from None
            if not accepted:
                raise RuntimeError("Slack rejected notification")

    return {"delivered": len(messages)}
