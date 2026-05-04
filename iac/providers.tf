terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.43.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "resize-image"
      Environment = terraform.workspace
    }
  }
}

# Para obtener las AZs disponibles en la region actual
data "aws_availability_zones" "available" {
  state = "available"
}
