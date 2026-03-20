# 1. Security Group for Bastion
resource "aws_security_group" "bastion" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. IAM Role and Instance Profile
resource "aws_iam_role" "bastion_role" {
  name = "${var.name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.name}-profile"
  role = aws_iam_role.bastion_role.name
}

# 3. Administrative Policy for Bastion (Fixes AccessDeniedException)
resource "aws_iam_role_policy" "bastion_eks_admin" {
  name = "${var.name}-eks-admin-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["*"]
        Resource = "*"
      }
    ]
  })
}

# 4. SSH Key Pair Generation
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key_pair" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "${path.module}/bastion-key.pem"
  file_permission = "0400"
}

# 5. The Bastion Instance
resource "aws_instance" "this" {
  ami                    = "ami-0c101f26f147fa7fd" # Amazon Linux 2023
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  key_name               = aws_key_pair.bastion_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y amazon-cloudwatch-agent
              curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.0/2024-09-12/bin/linux/amd64/kubectl
              chmod +x ./kubectl
              sudo mv ./kubectl /usr/local/bin/
              EOF

  tags = { Name = var.name }
}