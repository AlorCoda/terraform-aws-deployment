# output "cidr_block" {
#   value = module.vpc.vpc_cidr
# }

# output "public_subnets" {
#   value = module.vpc.public_subnets
# }

# output "ec2_instance_id" {
#   value = module.ec2.data.aws_ami.ubuntu.id
# }

# output "aws_security_group_id" {
#   value = module.security-group.security_group.web.id 
# }

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "bastion_host_public_ip" {
  description = "Public IP of bastion host"
  value       = module.bastion_host.instance_public_ips[0]
}

output "bastion_host_private_ip" {
  description = "Private IP of bastion host"
  value       = module.bastion_host.instance_private_ips[0]
}

output "database_instance_ids" {
  description = "IDs of database server instances"
  value       = module.database_servers.instance_ids
}

output "database_private_ips" {
  description = "Private IPs of database server instances"
  value       = module.database_servers.instance_private_ips
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.web_security_group.security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.db_security_group.security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.alb_security_group.security_group_id
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "s3_alb_logs_bucket" {
  description = "Name of S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "sns_alerts_topic_arn" {
  description = "ARN of SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow_log.name
}