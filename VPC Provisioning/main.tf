############################################
# Provider Configuration
############################################
provider "aws" {
  region = "us-east-1"
}

#############################################
# 1. VPC
#############################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "myproject-prod-vpc"
    Environment = "prod"
  }
}

#############################################
# 2. Data - Availability Zones
#############################################
data "aws_availability_zones" "available" {}

#############################################
# 3. Subnet CIDRs
#############################################
locals {
  public_subnets_cidrs  = ["10.0.1.0/24"]
  private_subnets_cidrs = ["10.0.101.0/24"]
}

#############################################
# 4. Public Subnets
#############################################
resource "aws_subnet" "public_subnets" {
  count                   = length(local.public_subnets_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "myproject-prod-public-${count.index + 1}"
  }
}

#############################################
# 5. Private Subnets
#############################################
resource "aws_subnet" "private_subnets" {
  count             = length(local.private_subnets_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "myproject-prod-private-${count.index + 1}"
  }
}

#############################################
# 6. Internet Gateway
#############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "myproject-prod-igw"
  }
}

#############################################
# 7. Elastic IPs for NAT Gateways
#############################################
resource "aws_eip" "nat_eips" {
  count  = length(local.public_subnets_cidrs)
  domain = "vpc"

  tags = {
    Name = "myproject-prod-eip-${count.index + 1}"
  }
}

#############################################
# 8. NAT Gateways (one per AZ)
#############################################
resource "aws_nat_gateway" "nat" {
  count         = length(local.public_subnets_cidrs)
  allocation_id = aws_eip.nat_eips[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "myproject-prod-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

#############################################
# 9. Route Tables
#############################################

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "myproject-prod-public-rt"
  }
}

# Private Route Tables (one per AZ)
resource "aws_route_table" "private_rt" {
  count  = length(local.private_subnets_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "myproject-prod-private-rt-${count.index + 1}"
  }
}

#############################################
# 10. Route Table Associations
#############################################

# Public Subnets
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnets (each uses NAT in same AZ)
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

