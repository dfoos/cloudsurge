provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id        = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnet
  instance_type = var.instance_type
  ami_id        = var.ami_id
  ec2_name      = var.ec2_name
  ec2_count     = var.ec2_count
}

module "lambda" {
  source = "./modules/lambda"
}

module "api" {
  source = "./modules/api"

  lambda_function_arn = module.lambda.function_arn
  aws_region          = var.aws_region
}

module "dynamo" {
  source = "./modules/dynamo"
}

output "api_endpoint" {
  value = module.api.api_endpoint
}

output "state_endpoint" {
  value = module.api.state_endpoint
}

output "api_key" {
  value     = module.api.api_key
  sensitive = true
}