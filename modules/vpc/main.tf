resource "aws_vpc" "custom" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "custom-vpc"
    }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.custom.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
}


resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id            = aws_vpc.custom.id
    cidr_block        = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index] 
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.custom.id
    tags = {
        Name = "custom-igw"
    }
}

resource "aws_eip" "nat" {
    count = length(var.public_subnet_cidrs)
    depends_on = [aws_internet_gateway.igw]  
}

resource "aws_nat_gateway" "main" {
    count = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id
}

##A Route Table in AWS is basically a set of rules that control where network traffic goes inside your VPC.

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.custom.id

    route = {
        cidr_block ="0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.custom.id

    route = {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main[count.index].id

    }
}

##resource that links a route table to a subnet (or gateway) inside a VPC.

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
        subnet_id      = aws_subnet.private[count.index].id
        route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
        subnet_id      = aws_subnet.public[count.index].id
        route_table_id = aws_route_table.public.id
  
}