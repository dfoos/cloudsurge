resource "aws_api_gateway_rest_api" "ec2_control" {
  name        = "EC2ControlAPI"
  description = "API to control EC2 instances and manage tokens"
}

resource "aws_api_gateway_resource" "ec2" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  parent_id   = aws_api_gateway_rest_api.ec2_control.root_resource_id
  path_part   = "ec2"
}

resource "aws_api_gateway_resource" "state" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  parent_id   = aws_api_gateway_resource.ec2.id
  path_part   = "state"
}

resource "aws_api_gateway_resource" "tokens" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  parent_id   = aws_api_gateway_rest_api.ec2_control.root_resource_id
  path_part   = "tokens"
}

resource "aws_api_gateway_resource" "tokens_count" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  parent_id   = aws_api_gateway_resource.tokens.id
  path_part   = "count"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.ec2.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "options_ec2" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.ec2.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
}

resource "aws_api_gateway_method" "get_state" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.state.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "options_state" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.state.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
}

resource "aws_api_gateway_method" "get_tokens_count" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.tokens_count.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "post_tokens_count" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.tokens_count.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "options_tokens_count" {
  rest_api_id      = aws_api_gateway_rest_api.ec2_control.id
  resource_id      = aws_api_gateway_resource.tokens_count.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.ec2.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "options_ec2" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.ec2.id
  http_method             = aws_api_gateway_method.options_ec2.http_method
  type                    = "MOCK"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "lambda_state" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.state.id
  http_method             = aws_api_gateway_method.get_state.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "options_state" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.state.id
  http_method             = aws_api_gateway_method.options_state.http_method
  type                    = "MOCK"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "lambda_tokens_count_get" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.tokens_count.id
  http_method             = aws_api_gateway_method.get_tokens_count.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "lambda_tokens_count_post" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.tokens_count.id
  http_method             = aws_api_gateway_method.post_tokens_count.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "options_tokens_count" {
  rest_api_id             = aws_api_gateway_rest_api.ec2_control.id
  resource_id             = aws_api_gateway_resource.tokens_count.id
  http_method             = aws_api_gateway_method.options_tokens_count.http_method
  type                    = "MOCK"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "get_state_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.state.id
  http_method = aws_api_gateway_method.get_state.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "get_tokens_count_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.get_tokens_count.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "post_tokens_count_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.post_tokens_count.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "options_ec2" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.options_ec2.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "options_state" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.state.id
  http_method = aws_api_gateway_method.options_state.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "options_tokens_count" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.options_tokens_count.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "get_state_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.state.id
  http_method = aws_api_gateway_method.get_state.http_method
  status_code = aws_api_gateway_method_response.get_state_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "get_tokens_count_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.get_tokens_count.http_method
  status_code = aws_api_gateway_method_response.get_tokens_count_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "post_tokens_count_200" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.post_tokens_count.http_method
  status_code = aws_api_gateway_method_response.post_tokens_count_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "options_ec2" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.options_ec2.http_method
  status_code = aws_api_gateway_method_response.options_ec2.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,x-api-key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "options_state" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.state.id
  http_method = aws_api_gateway_method.options_state.http_method
  status_code = aws_api_gateway_method_response.options_state.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,x-api-key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "options_tokens_count" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  resource_id = aws_api_gateway_resource.tokens_count.id
  http_method = aws_api_gateway_method.options_tokens_count.http_method
  status_code = aws_api_gateway_method_response.options_tokens_count.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,x-api-key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_state,
    aws_api_gateway_integration.lambda_tokens_count_get,
    aws_api_gateway_integration.lambda_tokens_count_post,
    aws_api_gateway_integration.options_ec2,
    aws_api_gateway_integration.options_state,
    aws_api_gateway_integration.options_tokens_count
  ]

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_integration.lambda,
      aws_api_gateway_integration.lambda_state,
      aws_api_gateway_integration.lambda_tokens_count_get,
      aws_api_gateway_integration.lambda_tokens_count_post,
      aws_api_gateway_integration.options_ec2,
      aws_api_gateway_integration.options_state,
      aws_api_gateway_integration.options_tokens_count
    ]))
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id = aws_api_gateway_rest_api.ec2_control.id
  deployment_id = aws_api_gateway_deployment.prod.id
  stage_name = "prod"
}

resource "aws_api_gateway_api_key" "ec2_control_key" {
  name = "ec2-control-key"
}

resource "aws_api_gateway_usage_plan" "ec2_control" {
  name = "ec2-control-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.ec2_control.id
    stage = aws_api_gateway_stage.prod.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "ec2_control" {
  key_id = aws_api_gateway_api_key.ec2_control_key.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.ec2_control.id
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.ec2_control.execution_arn}/*/*"
}