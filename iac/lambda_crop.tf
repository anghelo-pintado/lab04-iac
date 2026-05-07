data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "../${path.root}/lambdas/crop"
  output_path = "${path.module}/artifacts/crop.zip"
}

# role
resource "aws_iam_role" "crop_lambda" {
  name = "${local.prefix}-crop-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.prefix}-crop-lambda-role" }
}

# policy
resource "aws_iam_role_policy_attachment" "crop_basic" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# solo GetObject uploads/, PutObject processed/ y SQS
resource "aws_iam_role_policy" "crop_permissions" {
  name = "s3-sqs-permissions"
  role = aws_iam_role.crop_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.images.arn}/uploads/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.images.arn}/processed/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = aws_sqs_queue.main.arn
      },
    ]
  })
}

# function
resource "aws_lambda_function" "crop" {
  function_name = "${local.prefix}-crop"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  filename      = data.archive_file.crop_zip.output_path

  source_code_hash = filebase64sha256(data.archive_file.crop_zip.output_path)

  memory_size = var.lambda_memory_crop
  timeout     = var.lambda_timeout_crop
  role        = aws_iam_role.crop_lambda.arn

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.bucket
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.crop_lambda,
    aws_iam_role_policy_attachment.crop_basic,
    aws_iam_role_policy_attachment.crop_vpc,
  ]

  tags = { Name = "${local.prefix}-crop" }
}

# esm 
resource "aws_lambda_event_source_mapping" "crop_sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5

  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}
