output "api_handler_arn" {
  description = "API Handler Lambda ARN"
  value       = aws_lambda_function.api_handler.arn
}

output "event_processor_arn" {
  description = "Event Processor Lambda ARN"
  value       = aws_lambda_function.event_processor.arn
}

output "data_transformer_arn" {
  description = "Data Transformer Lambda ARN"
  value       = aws_lambda_function.data_transformer.arn
}

output "notification_arn" {
  description = "Notification Lambda ARN"
  value       = aws_lambda_function.notification.arn
}

output "file_processor_arn" {
  description = "File Processor Lambda ARN"
  value       = aws_lambda_function.file_processor.arn
}

output "workflow_orchestrator_arn" {
  description = "Workflow Orchestrator Lambda ARN"
  value       = aws_lambda_function.workflow_orchestrator.arn
}

output "function_arns" {
  description = "Map of all Lambda function ARNs"
  value = {
    api_handler         = aws_lambda_function.api_handler.arn
    event_processor     = aws_lambda_function.event_processor.arn
    data_transformer    = aws_lambda_function.data_transformer.arn
    notification        = aws_lambda_function.notification.arn
    file_processor      = aws_lambda_function.file_processor.arn
    workflow_orchestrator = aws_lambda_function.workflow_orchestrator.arn
  }
}
