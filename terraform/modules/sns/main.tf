resource "aws_sns_topic" "main" {
  name              = "${var.project_name}-${var.environment}-topic"
  display_name      = "${var.project_name} ${var.environment} Notifications"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-sns"
    }
  )
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.email_endpoint != "" ? var.email_endpoint : "admin@example.com"
}
