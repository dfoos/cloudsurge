variable "vpc_id" {
  description = "VPC ID"
}

variable "public_subnet" {
  description = "Public subnet ID"
}

variable "instance_type" {
  description = "EC2 instance type"
}

variable "ami_id" {
  description = "AMI ID"
}

variable "ec2_name" {
  description = "Base name of instance"
}

variable "ec2_count" {
  description = "Number of instances to create"
}