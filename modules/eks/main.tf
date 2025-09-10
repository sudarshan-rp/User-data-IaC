resource "aws_eks_cluster" "custom" {
  name = "custom-eks"
  version = var.cluster_version

  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
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

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
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


resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# OIDC provider for EKS
data "tls_certificate" "eks" {
  url = aws_eks_cluster.custom.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.custom.identity[0].oidc[0].issuer
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
    depends_on = [aws_eks_cluster.custom]

}

resource "aws_eks_addon" "addons" {
  for_each     = toset(["vpc-cni", "kube-proxy", "coredns","metrics-server","eks-pod-identity-agent"])
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = each.value
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.custom.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  depends_on              = [aws_iam_role_policy_attachment.ebs_csi_policy]
}

resource "aws_eks_access_entry" "console_access" {
  cluster_name  = aws_eks_cluster.custom.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.custom]
}

resource "aws_eks_access_policy_association" "console_admin" {
  cluster_name  = aws_eks_cluster.custom.name
  principal_arn = aws_eks_access_entry.console_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.console_access]
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}