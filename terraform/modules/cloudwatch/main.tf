# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-serverless-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" = "Sum", "period" = 300 }],
            ["AWS/Lambda", "Errors", { "stat" = "Sum", "period" = 300 }],
            ["AWS/Lambda", "Duration", { "stat" = "Average", "period" = 300 }],
            ["AWS/Lambda", "Throttles", { "stat" = "Sum", "period" = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { "stat" = "Sum", "period" = 300 }],
            ["AWS/ApiGateway", "Latency", { "stat" = "Average", "period" = 300 }],
            ["AWS/ApiGateway", "4XXError", { "stat" = "Sum", "period" = 300 }],
            ["AWS/ApiGateway", "5XXError", { "stat" = "Sum", "period" = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "API Gateway Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { "stat" = "Sum", "period" = 300 }],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", { "stat" = "Sum", "period" = 300 }],
            ["AWS/DynamoDB", "ThrottledRequests", { "stat" = "Sum", "period" = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "DynamoDB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/States", "ExecutionsStarted", { "stat" = "Sum", "period" = 300 }],
            ["AWS/States", "ExecutionsSucceeded", { "stat" = "Sum", "period" = 300 }],
            ["AWS/States", "ExecutionsFailed", { "stat" = "Sum", "period" = 300 }],
            ["AWS/States", "ExecutionTime", { "stat" = "Average", "period" = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Step Functions Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors lambda errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = keys(var.lambda_functions)[0]
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "This metric monitors API Gateway latency"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = var.tags
}
