#Configuring the provider "AWS" in this instance

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

# provider "aws" {
#   region = var.region
# }
