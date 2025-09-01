variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
    type      = string
    default = "0.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "value for the privet subnet CIDR block"
  type = list(string)
  default = [ "10.0.1.0/24","10.0.2.0/24" ]
}

variable "public_subnet_cidrs" {
  description = "value for the public subnet CIDR block"
  type = list(string)
  default = [ "10.0.3.0/24","10.0.4.0/24" ]
}

variable "availability_zones" {
  description = "values for the availability zones"
    type      = list(string)
    default = [ "us-east-1a", "us-east-1b" ]
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
    type      = string
    default = "1.31"
  
}

variable "node_groups" {
  description = "Map of node group configurations"
    type      = map(object({
      instance_type = list(string)
      desired_capacity = number
      min_size = number
      max_size = number
    }))
    default = {
      ng-1 = {
        instance_type = ["t3.medium"]
        desired_capacity = 1
        min_size = 1
        max_size = 2 
      }
    }
  
}


