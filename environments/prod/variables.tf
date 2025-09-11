# variable "aws_region" {
#   description = "AWS region"
#   type        = string
# }

# variable "cidr_block" {
#   description = "CIDR block for the VPC"
#   type        = string
# }

# variable "public_subnets" {
#   description = "Public subnets"
#   type        = list(string)
# }

# variable "private_subnets" {
#   description = "Private subnets"
#   type        = string
# }

# variable "instance_type" {
#   description = "EC2 instance type"
#   type        = string
# }

# variable "ami" {
#   description = "AMI ID for EC2"
#   type        = string
# }

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "web_min_size" {
  description = "Minimum number of web server instances"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum number of web server instances"
  type        = number
  default     = 10
}

variable "web_desired_capacity" {
  description = "Desired number of web server instances"
  type        = number
  default     = 3
}

variable "db_instance_count" {
  description = "Number of database server instances"
  type        = number
  default     = 2
}

variable "db_instance_type" {
  description = "Instance type for database servers"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = []
}

variable "bastion_cidr" {
  description = "CIDR block for bastion host access"
  type        = string
  default     = "10.1.1.0/24"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancer"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner        = "DevOps Team"
    Environment  = "prod"
    CostCenter   = "Engineering"
    Backup       = "Required"
    Monitoring   = "Critical"
    Compliance   = "SOC2"
  }
}