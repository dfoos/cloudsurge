resource "aws_iam_role" "lambda_role" {
  name = "lambda-ec2-control-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-ec2-control-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
            {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "ec2_control" {
  filename         = "${path.module}/lambda_function/ec2_control.zip"
  function_name    = "ec2_control"
  role             = aws_iam_role.lambda_role.arn
  handler          = "ec2_control.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/lambda_function/ec2_control.zip")
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = "test"
    }
  }
}