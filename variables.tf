variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro" # Free-tier eligible
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0f3f13f145e66a0a3" # Amazon Linux 2 in us-east-1
}

variable "ec2_name" {
  description = "Base name of instance"
  default     = "cloudsurge"
}

variable "ec2_count" {
  description = "Number of instances to create"
  default     = 2
}