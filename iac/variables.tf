variable "aws_region" {
  description = "Región de despliegue AWS"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas"
  type        = list(string)
}

variable "lambda_memory_upload" {
  description = "Memoria en MB para upload-lambda"
  type        = number
}

variable "lambda_memory_crop" {
  description = "Memoria en MB para crop-lambda"
  type        = number
}

variable "lambda_timeout_upload" {
  description = "Timeout en segundos para upload-lambda"
  type        = number
}

variable "lambda_timeout_crop" {
  description = "Timeout en segundos para crop-lambda"
  type        = number
}

variable "s3_uploads_expiration_days" {
  description = "Días hasta expirar objetos en uploads/"
  type        = number
}

variable "s3_processed_expiration_days" {
  description = "Días hasta expirar objetos en processed/"
  type        = number
}

variable "log_retention_days" {
  description = "Retención de logs en CloudWatch"
  type        = number
}
