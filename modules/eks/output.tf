output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.custom.endpoint
  
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.custom.name
  
}
