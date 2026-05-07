# sns
resource "aws_sns_topic" "alerts" {
  name = "${local.prefix}-alerts"

  tags = {
    Name = "${local.prefix}-alerts"
  }
}

# vigilar dlq
resource "aws_cloudwatch_metric_alarm" "dql_messages" {
  alarm_name          = "${local.prefix}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.prefix}-alarm-dlq-messages"
  }
}
