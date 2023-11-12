
output "sns_topic_arn" {
  value = aws_sns_topic.topic[0].arn
}

output "sns_topic_name" {
  value = aws_sns_topic.topic[0].name
}
