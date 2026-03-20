region      = "us-east-1"
environment = "dev"
vpc_cidr    = "10.0.0.0/16"

azs             = ["us-east-1a", "us-east-1b"]
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
allowed_ssh_cidr = ["49.43.219.82/32"]


desired_size = 1
min_size     = 1
max_size     = 2