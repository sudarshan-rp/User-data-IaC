resource "aws_vpc" "custom" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    
    tags = {
        Name        = "custom-vpc"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.custom.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name                              = "private-subnet-${count.index + 1}"
    Type                              = "private"
    Environment                       = "dev"
    Project                           = "eks-infrastructure"
    ManagedBy                         = "terraform"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/custom-eks" = "shared"
  }
}

resource "aws_subnet" "public" {
    count                   = length(var.public_subnet_cidrs)
    vpc_id                  = aws_vpc.custom.id
    cidr_block              = var.public_subnet_cidrs[count.index]
    availability_zone       = var.availability_zones[count.index]
    map_public_ip_on_launch = true
    
    tags = {
        Name                             = "public-subnet-${count.index + 1}"
        Type                             = "public"
        Environment                      = "dev"
        Project                          = "eks-infrastructure"
        ManagedBy                        = "terraform"
        "kubernetes.io/role/elb"         = "1"
        "kubernetes.io/cluster/custom-eks" = "shared"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.custom.id
    
    tags = {
        Name        = "custom-igw"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_eip" "nat" {
    count      = length(var.public_subnet_cidrs)
    domain     = "vpc"
    depends_on = [aws_internet_gateway.igw]
    
    tags = {
        Name        = "nat-eip-${count.index + 1}"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_nat_gateway" "main" {
    count         = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id
    
    tags = {
        Name        = "nat-gateway-${count.index + 1}"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.custom.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    
    tags = {
        Name        = "public-route-table"
        Type        = "public"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.custom.id

  route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
    
    tags = {
        Name        = "private-route-table-${count.index + 1}"
        Type        = "private"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table_association" "private" {
    count          = length(var.private_subnet_cidrs)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
    count          = length(var.public_subnet_cidrs)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}