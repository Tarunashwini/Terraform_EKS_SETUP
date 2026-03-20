terraform {
  backend "s3" {
    bucket = "eks-terraform-state-tarun"
    key = "eks/dev/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}