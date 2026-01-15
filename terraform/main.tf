terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    # Configure backend in terraform.tfvars or via environment variables
    # bucket = "your-terraform-state-bucket"
    # key    = "serverless-lambda/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "serverless-event-driven-lambda"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name    = var.project_name
  environment     = var.environment
  api_name        = "${var.project_name}-${var.environment}-api"
  throttle_rate_limit = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit

  tags = local.common_tags
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# SQS Module
module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# SNS Module
module "sns" {
  source = "./modules/sns"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# Lambda Functions Module
module "lambda_functions" {
  source = "./modules/lambda-functions"

  project_name    = var.project_name
  environment     = var.environment
  api_gateway_id  = module.api_gateway.api_id
  api_gateway_execution_arn = "${module.api_gateway.api_endpoint}/*/*"
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn = module.dynamodb.table_arn
  s3_bucket_name  = module.s3.bucket_name
  s3_bucket_arn   = module.s3.bucket_arn
  sqs_queue_url   = module.sqs.queue_url
  sqs_queue_arn   = module.sqs.queue_arn
  sns_topic_arn   = module.sns.topic_arn

  tags = local.common_tags
}

# EventBridge Module
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name    = var.project_name
  environment     = var.environment
  lambda_functions = {
    event_processor = module.lambda_functions.event_processor_arn
    data_transformer = module.lambda_functions.data_transformer_arn
    notification    = module.lambda_functions.notification_arn
  }

  tags = local.common_tags
}

# Step Functions Module
module "step_functions" {
  source = "./modules/step-functions"

  project_name    = var.project_name
  environment     = var.environment
  lambda_functions = {
    data_transformer = module.lambda_functions.data_transformer_arn
    file_processor   = module.lambda_functions.file_processor_arn
    notification     = module.lambda_functions.notification_arn
    workflow_handler = module.lambda_functions.workflow_orchestrator_arn
  }

  tags = local.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name    = var.project_name
  environment     = var.environment
  api_gateway_id  = module.api_gateway.api_id
  lambda_functions = module.lambda_functions.function_arns
  step_functions_arn = module.step_functions.state_machine_arn

  tags = local.common_tags
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
