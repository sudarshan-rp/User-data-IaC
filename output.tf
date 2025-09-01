output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
  
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
  
}   

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
  
}   