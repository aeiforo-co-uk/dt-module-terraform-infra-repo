# Locals
locals {
  vpc_id                 = try(aws_vpc.this[0].id, "")
  create_vpc             = var.create_vpc
  create_public_subnets  = local.create_vpc && length(var.public_subnets) > 0
  create_private_subnets = local.create_vpc && length(var.private_subnets) > 0
}

# VPC
resource "aws_vpc" "this" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = var.cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.name}-private-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "${var.name}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  count  = local.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Add Route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# Private Route Table
resource "aws_route_table" "private" {
  count  = local.create_private_subnets ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "${var.name}-private-rt"
  }
}

# NAT Gateway Elastic IP
resource "aws_eip" "nat" {
  count = 1

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = 1
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat[0].id

  tags = {
    Name = "${var.name}-nat"
  }
}

# Add NAT Gateway Route to Private Route Table
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Security Group with Dynamic Ingress/Egress Rules
resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this[0].id
  name   = "${var.name}-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value["from_port"]
      to_port     = egress.value["to_port"]
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"]
    }
  }

  tags = {
    Name = "${var.name}-sg"
  }
}
