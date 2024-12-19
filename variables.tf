variable "region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu Server 22.04 LTS AMI ID"
  type        = string # Update based on your region
}

variable "datadog_api_key" {
  description = "Datadog API Key"
  type        = string
}
