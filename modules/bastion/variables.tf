variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "instance_type" { default = "t3.micro" }
variable "allowed_ssh_cidr" { type = list }
variable "cluster_name" { type = string }