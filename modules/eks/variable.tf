variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
    type      = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
    type      = list(string)
}

