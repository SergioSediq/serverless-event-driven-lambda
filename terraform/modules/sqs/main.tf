resource "aws_sqs_queue" "main" {
  name                      = "${var.project_name}-${var.environment}-queue"
  message_retention_seconds = 345600 # 4 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 0

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-sqs"
    }
  )
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-${var.environment}-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-dlq"
    }
  )
}

resource "aws_sqs_queue_redrive_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
