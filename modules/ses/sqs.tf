
resource "aws_sqs_queue" "queue" {
  name                       = "${module.context.id}-queue"
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 300
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter_queue.arn}\",\"maxReceiveCount\":4}"
  tags                       = local.tags
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name = "${module.context.id}-dlq"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}

data "aws_iam_policy_document" "sqs_policy" {
  policy_id = "${module.context.id}-queue"
  statement {
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = ["${aws_sqs_queue.queue.arn}"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.sns_topic.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "ses_queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}
