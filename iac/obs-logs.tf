# log group - api gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.prefix}-logs-api-gateway"
  }
}

# log group - lambdas
resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${local.prefix}-upload"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.prefix}-logs-upload"
  }
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${local.prefix}-crop"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.prefix}-logs-crop"
  }
}

# rol iam para api gateway --escribir logs--> cloudwatch
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.prefix}-api-gateway-cloudwatch-role"
  }
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch]
}
