variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type      = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type      = list(string)
}

variable "node_groups" {
  description = "Map of node group configurations"
  type      = map(object({
      instance_types = list(string)
      scaling_config = object({
        desired_capacity = number
        min_size = number
        max_size = number
    })}))
  
}
