data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "../${path.root}/lambdas/upload"
  output_path = "${path.module}/artifacts/upload.zip"
}

# role
resource "aws_iam_role" "upload_lambda" {
  name = "${local.prefix}-upload-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.prefix}-upload-lambda-role" }
}

# policy
resource "aws_iam_role_policy_attachment" "upload_basic" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# solo PutObject en upload/
resource "aws_iam_role_policy" "upload_s3" {
  name = "s3-put-uploads"
  role = aws_iam_role.upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.images.arn}/uploads/*"
    }]
  })
}

# function
resource "aws_lambda_function" "upload" {
  function_name = "${local.prefix}-upload"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  filename      = data.archive_file.upload_zip.output_path

  source_code_hash = filebase64sha256(data.archive_file.upload_zip.output_path)

  memory_size = var.lambda_memory_upload
  timeout     = var.lambda_timeout_upload
  role        = aws_iam_role.upload_lambda.arn

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.upload_lambda,
    aws_iam_role_policy_attachment.upload_basic,
    aws_iam_role_policy_attachment.upload_vpc,
  ]

  tags = { Name = "${local.prefix}-upload" }
}
