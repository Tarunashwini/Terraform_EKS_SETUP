resource "aws_vpc" "terra_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.environment}-vpc" }
}

resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags   = { Name = "${var.environment}-igw" }
}

resource "aws_subnet" "terra_public_subnet" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "terra_private_subnet" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = { "kubernetes.io/role/internal-elb" = "1" }
}

# Public Routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.terra_public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Routing (NAT)
resource "aws_eip" "terra_eip" {
  count  = length(var.azs)
  domain = "vpc"
}

resource "aws_nat_gateway" "terra_nat" {
  count         = length(var.azs)
  allocation_id = aws_eip.terra_eip[count.index].id
  subnet_id     = aws_subnet.terra_public_subnet[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terra_nat[count.index].id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.terra_private_subnet[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}