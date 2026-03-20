output "terra_vpc_id" {
  value = aws_vpc.terra_vpc.id
}

output "terra_private_subnets" {
  value = aws_subnet.terra_private_subnet[*].id
}

output "terra_public_subnets" {
  value = aws_subnet.terra_public_subnet[*].id
}