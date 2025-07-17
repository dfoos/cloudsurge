output "api_endpoint" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/ec2"
}

output "state_endpoint" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/ec2/state"
}

output "api_key" {
  value = aws_api_gateway_api_key.ec2_control_key.value
  sensitive = true
}