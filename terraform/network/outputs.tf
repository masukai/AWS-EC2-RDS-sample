output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_1a.id,
    aws_subnet.public_dummy.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
}

output "private_subnet_1a_id" {
  value = aws_subnet.private_1a.id
}
