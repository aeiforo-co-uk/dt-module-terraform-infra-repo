# Outputs

output "vpc_id" {
  value = aws_vpc.this[0].id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
  description = "The IDs of the public subnets"
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
  description = "The IDs of the private subnets"
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this[0].id
  description = "The ID of the Internet Gateway"
  condition = var.create_igw
}

output "public_route_table_id" {
  value = aws_route_table.public[0].id
  description = "The ID of the public route table"
  condition = local.create_public_subnets
}

output "private_route_table_id" {
  value = aws_route_table.private[0].id
  description = "The ID of the private route table"
  condition = local.create_private_subnets
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this[0].id
  description = "The ID of the NAT Gateway"
}

output "security_group_id" {
  value = aws_security_group.this.id
  description = "The ID of the Security Group"
}
