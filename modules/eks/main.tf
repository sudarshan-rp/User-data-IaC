resource "aws_eks_cluster" "custom" {
  name = "custom-eks"
  version = var.cluster_version

  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "eks.amazonaws.com"
            }
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}   

resource "aws_iam_role" "nodes" {
  name = "eks-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        }
        ]
    })
  
}


resource "aws_iam_role_policy_attachment" "node_policy" {
  for_each =toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  policy_arn = each.value
    role       = aws_iam_role.nodes.name

}

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups
    cluster_name    = aws_eks_cluster.custom.name
    node_group_name = each.key
    node_role_arn   = aws_iam_role.nodes.arn
    subnet_ids      = var.private_subnet_ids
    scaling_config {
        desired_size   = each.value.scaling_config.desired_capacity
        max_size     = each.value.scaling_config.max_size
        min_size     = each.value.scaling_config.min_size

    }
    disk_size = 20
    instance_types = each.value.instance_types
    depends_on = [aws_eks_cluster.custom, aws_iam_role_policy_attachment.node_policy]

}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "vpc-cni"
  depends_on = [aws_eks_cluster.custom]
} 

resource "aws_eks_addon" "vpc_kube_proxy" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "kube-proxy"
  depends_on = [aws_eks_cluster.custom]     
  
}

resource "aws_eks_addon" "vpc_core_dns" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "coredns"
  depends_on = [aws_eks_cluster.custom]
  
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on = [aws_eks_cluster.custom]         
  
}