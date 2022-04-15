terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "example_lambda" {
  filename         = "package.zip"
  function_name    = "blog-shanenolan-dev"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function_url_terraform.main.lambda_handler"
  source_code_hash = filebase64sha256("package.zip")
  runtime          = "python3.9"
}

resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.example_lambda.arn
  authorization_type = "NONE"
}

output "function_url" {
  description = "Function URL."
  value       = aws_lambda_function_url.lambda_function_url.function_url
}
