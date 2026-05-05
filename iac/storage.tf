# suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# s3
resource "aws_s3_bucket" "images" {
  bucket        = "${local.prefix}-image-processor-${terraform.workspace}-images-${random_id.bucket_suffix.hex}"
  force_destroy = terraform.workspace != "prod"

  tags = {
    Name = "${local.prefix}-images"
  }
}

# privatizamos
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# versionado
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# cifrado
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  depends_on = [aws_s3_bucket_versioning.images]

  rule {
    id     = "expired-uploads-images"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = var.s3_uploads_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "expired-processed-images"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    expiration {
      days = var.s3_processed_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# vpc endpoint para s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.images.arn}/*"
      }
    ]
  })

  tags = {
    Name = "${local.prefix}-vpc-endpoint-s3"
  }
}
