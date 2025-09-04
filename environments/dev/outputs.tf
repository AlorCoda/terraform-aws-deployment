output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The public subnet ids"
  value = module.vpc.public_subnet_ids
}

output "ec2_instance_id" {
  description = "The EC2 instance id"
  value = module.ec2.instance_id
}

output "security_group_id" {
  description = "The security group id"
  value = module.sg.security_group_id 
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ami_id" {
  description = "AMI ID used for the EC2 instance"
  value       = data.aws_ami.ubuntu.id
}