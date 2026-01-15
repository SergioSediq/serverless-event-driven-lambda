variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_name" {
  description = "API Gateway name"
  type        = string
}

variable "throttle_rate_limit" {
  description = "Throttle rate limit"
  type        = number
  default     = 1000
}

variable "throttle_burst_limit" {
  description = "Throttle burst limit"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
