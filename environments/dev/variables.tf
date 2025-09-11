# variable "aws_region" {
#   description = "AWS region"
#   type        = string
#   default     = "us-west-2"
# }

# variable "cidr_block" {
#   description = "CIDR block for the VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }

# variable "public_subnets" {
#   description = "Public subnets"
#   type        = list(string)
#   default     = ["10.0.1.0/24", "10.0.2.0/24"]
# }

# variable "private_subnets" {
#   description = "Private subnets"
#   type        = string
#   default     = "10.0.3.0/24"
# }

# variable "instance_type" {
#   description = "EC2 instance type"
#   type        = string
#   default     = "t3.micro"
# }
# variable "ami_id" {
#   description = "AMI ID for EC2"
#   type        = string
#   default     = "ami-03aa99ddf5498ceb9"
# }

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "web_instance_count" {
  description = "Number of web server instances"
  type        = number
  default     = 2
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_count" {
  description = "Number of database server instances"
  type        = number
  default     = 1
}

variable "db_instance_type" {
  description = "Instance type for database servers"
  type        = string
  default     = "t3.small"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {
    Owner = "DevOps Team"
  }
}