variable "vpc_cidr" {
  description = "value for the VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "value for the private subnet CIDR block"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "value for the public subnet CIDR block"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "values for the availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = "1.33"
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    scaling_config = object({
      desired_capacity = number
      min_size         = number
      max_size         = number
  }) }))
  default = {
    general = {
      instance_types = ["t3.small"]
      scaling_config = {
        desired_capacity = 2
        min_size         = 2
        max_size         = 3
      }
    }
  }

}


