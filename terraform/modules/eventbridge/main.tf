# EventBridge Bus
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-${var.environment}-bus"

  tags = var.tags
}

# EventBridge Rule for Event Processing
resource "aws_cloudwatch_event_rule" "event_processor" {
  name           = "${var.project_name}-${var.environment}-event-processor-rule"
  description    = "Rule to trigger event processor"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["${var.project_name}.events"]
    detail-type = ["Event Created"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "event_processor" {
  rule      = aws_cloudwatch_event_rule.event_processor.name
  target_id = "EventProcessorTarget"
  arn       = var.lambda_functions.event_processor
}

resource "aws_lambda_permission" "event_processor" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_functions.event_processor
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_processor.arn
}

# EventBridge Rule for Data Transformation
resource "aws_cloudwatch_event_rule" "data_transformer" {
  name           = "${var.project_name}-${var.environment}-data-transformer-rule"
  description    = "Rule to trigger data transformer"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["${var.project_name}.events"]
    detail-type = ["Data Transformation Required"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "data_transformer" {
  rule      = aws_cloudwatch_event_rule.data_transformer.name
  target_id = "DataTransformerTarget"
  arn       = var.lambda_functions.data_transformer
}

resource "aws_lambda_permission" "data_transformer" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_functions.data_transformer
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.data_transformer.arn
}

# Scheduled Rule (example: daily processing)
resource "aws_cloudwatch_event_rule" "scheduled" {
  name                = "${var.project_name}-${var.environment}-scheduled-rule"
  description         = "Scheduled rule for daily processing"
  schedule_expression = "rate(1 day)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "notification" {
  rule      = aws_cloudwatch_event_rule.scheduled.name
  target_id = "NotificationTarget"
  arn       = var.lambda_functions.notification

  input = jsonencode({
    message = "Daily scheduled notification",
    subject = "Daily Report"
  })
}

resource "aws_lambda_permission" "notification" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_functions.notification
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled.arn
}
