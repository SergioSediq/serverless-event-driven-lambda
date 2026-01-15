# IAM Role for Lambda functions
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lambda functions
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "${var.dynamodb_table_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Handler Lambda
data "archive_file" "api_handler" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/api-handler/index.py"
  output_path = "${path.module}/api-handler.zip"
  depends_on  = [null_resource.lambda_dependencies]
}

resource "null_resource" "lambda_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/../../lambda/api-handler/requirements.txt")
  }
}

resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = "${var.project_name}-${var.environment}-api-handler"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      SQS_QUEUE_URL  = var.sqs_queue_url
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# Event Processor Lambda
data "archive_file" "event_processor" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/event-processor/index.py"
  output_path = "${path.module}/event-processor.zip"
}

resource "aws_lambda_function" "event_processor" {
  filename         = data.archive_file.event_processor.output_path
  function_name    = "${var.project_name}-${var.environment}-event-processor"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      SQS_QUEUE_URL  = var.sqs_queue_url
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# Data Transformer Lambda
data "archive_file" "data_transformer" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/data-transformer/index.py"
  output_path = "${path.module}/data-transformer.zip"
}

resource "aws_lambda_function" "data_transformer" {
  filename         = data.archive_file.data_transformer.output_path
  function_name    = "${var.project_name}-${var.environment}-data-transformer"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# Notification Lambda
data "archive_file" "notification" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/notification/index.py"
  output_path = "${path.module}/notification.zip"
}

resource "aws_lambda_function" "notification" {
  filename         = data.archive_file.notification.output_path
  function_name    = "${var.project_name}-${var.environment}-notification"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# File Processor Lambda
data "archive_file" "file_processor" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/file-processor/index.py"
  output_path = "${path.module}/file-processor.zip"
}

resource "aws_lambda_function" "file_processor" {
  filename         = data.archive_file.file_processor.output_path
  function_name    = "${var.project_name}-${var.environment}-file-processor"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      S3_BUCKET      = var.s3_bucket_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# Workflow Orchestrator Lambda
data "archive_file" "workflow_orchestrator" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/workflow-orchestrator/index.py"
  output_path = "${path.module}/workflow-orchestrator.zip"
}

resource "aws_lambda_function" "workflow_orchestrator" {
  filename         = data.archive_file.workflow_orchestrator.output_path
  function_name    = "${var.project_name}-${var.environment}-workflow-orchestrator"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

# API Gateway Integration for API Handler
resource "aws_apigatewayv2_integration" "api_handler" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api_handler.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_handler" {
  api_id    = var.api_gateway_id
  route_key = "POST /api/events"
  target    = "integrations/${aws_apigatewayv2_integration.api_handler.id}"
}

resource "aws_apigatewayv2_route" "api_handler_get" {
  api_id    = var.api_gateway_id
  route_key = "GET /api/events"
  target    = "integrations/${aws_apigatewayv2_integration.api_handler.id}"
}

# Lambda permissions
resource "aws_lambda_permission" "api_handler" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# S3 Event Notification for File Processor
resource "aws_s3_bucket_notification" "file_processor" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "file_processor" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# SQS Event Source Mapping for Event Processor
resource "aws_lambda_event_source_mapping" "event_processor" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.event_processor.arn
  batch_size       = 10
  enabled          = true
}
