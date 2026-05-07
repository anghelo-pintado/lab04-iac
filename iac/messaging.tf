# queue
resource "aws_sqs_queue" "dlq" {
  name = "${local.prefix}-image-dlq"

  message_retention_seconds = 1209600

  tags = {
    Name = "${local.prefix}-image-dlq"
  }
}

resource "aws_sqs_queue" "main" {
  name = "${local.prefix}-image-queue"

  visibility_timeout_seconds = var.lambda_timeout_crop * 30

  message_retention_seconds = 86400

  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.prefix}-image-queue"
  }
}

# policy s3 -> sqs
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.images.arn
          }
        }
      }
    ]
  })
}

# event notification s3 -> sqs
resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.images.id

  depends_on = [aws_sqs_queue_policy.main]

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}

# sqs interface endpoint
resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sqs.id]

  tags = {
    Name = "${local.prefix}-vpc-endpoint-sqs"
  }
}
