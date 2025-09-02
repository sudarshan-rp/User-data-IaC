output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint

}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id

}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name

}   