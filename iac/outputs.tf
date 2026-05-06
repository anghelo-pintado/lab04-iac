output "api_endpoint" {
  description = "URL del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "upload_url" {
  description = "Endpoint para subir imágenes"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/upload"
}

output "s3_bucket_name" {
  description = "Nombre bucket S3"
  value       = aws_s3_bucket.images.bucket
}

output "sqs_queue_url" {
  description = "URL Main Queue SQS"
  value       = aws_sqs_queue.main.url
}

output "sqs_dlq_url" {
  description = "URL Dead Letter Queue"
  value       = aws_sqs_queue.dlq.url
}

output "upload_lambda_name" {
  description = "Nombre de la función upload-lambda"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda_name" {
  description = "Nombre de la función crop-lambda"
  value       = aws_lambda_function.crop.function_name
}
