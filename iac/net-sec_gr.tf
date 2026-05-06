# rangos de servicios para S3
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

# security groups
resource "aws_security_group" "vpc_endpoint_sqs" {
  name        = "${local.prefix}-sg-vpc-endpoint-sqs"
  description = "Permite Lambda a SQS a traves del VPC Endpoint"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-sg-vpc-endpoint-sqs"
  }
}

resource "aws_security_group" "upload_lambda" {
  name        = "${local.prefix}-sg-upload-lambda"
  description = "Egress Https a S3 y SQS enpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-sg-upload-lambda"
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "${local.prefix}-sg-crop-lambda"
  description = "Egress Https a S3 y SQS enpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-sg-crop-lambda"
  }
}

# Egress s3 via gateway endpoint
resource "aws_vpc_security_group_egress_rule" "upload_lambda_to_s3" {
  security_group_id = aws_security_group.upload_lambda.id
  description       = "Permite upload_lambda a S3 via Gateway Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "crop_lambda_to_s3" {
  security_group_id = aws_security_group.crop_lambda.id
  description       = "Permite crop_lambda a S3 via Gateway Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
}

# Egress sqs interface endpoint
resource "aws_vpc_security_group_egress_rule" "upload_lambda_to_sqs" {
  security_group_id = aws_security_group.upload_lambda.id
  description       = "Permite upload_lambda a SQS via Interface Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = aws_security_group.vpc_endpoint_sqs.id
}

resource "aws_vpc_security_group_egress_rule" "crop_lambda_to_sqs" {
  security_group_id = aws_security_group.crop_lambda.id
  description       = "Permite crop_lambda a SQS via Interface Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = aws_security_group.vpc_endpoint_sqs.id
}

# Ingress al VPC Endpoint de SQS desde Lambda
resource "aws_vpc_security_group_ingress_rule" "sqs_from_upload_lambda" {
  security_group_id = aws_security_group.vpc_endpoint_sqs.id
  description       = "Permite SQS de upload_lambda via Interface Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = aws_security_group.upload_lambda.id
}

resource "aws_vpc_security_group_ingress_rule" "sqs_from_crop_lambda" {
  security_group_id = aws_security_group.vpc_endpoint_sqs.id
  description       = "Permite SQS de crop_lambda via Interface Endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = aws_security_group.crop_lambda.id
}
