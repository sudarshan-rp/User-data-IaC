variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
    type      = string
}

variable "private_subnet_cidrs" {
  description = "values for the private subnet CIDR blocks"
  type      = list(string)
}

variable "public_subnet_cidrs" {
  description = "values for the public subnet CIDR blocks"
  type      = list(string)
}

variable "availability_zones" {
  description = "values for the availability zones"
  type      = list(string)
  
}   




