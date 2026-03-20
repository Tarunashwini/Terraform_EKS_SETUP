output "bastion_public_ip" { value = aws_instance.this.public_ip }
output "bastion_role_arn" { value = aws_iam_role.bastion_role.arn }
output "bastion_sg_id" { value = aws_security_group.bastion.id }