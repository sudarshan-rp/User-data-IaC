#Creates the EKS cluster resource with the specified name, version, IAM role, networking, and access settings.
# The cluster depends on the IAM role policy attachment to ensure proper permissions are in place before creation.

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

  tags = {
    Name        = "custom-eks"
    Environment = "dev"
    Project     = "eks-infrastructure"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}


#-------------------------------------------
#Defines an IAM role that the EKS control plane will assume to manage AWS resources.
#The trust policy allows the EKS service to assume this role.
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

    tags = {
        Name        = "eks-cluster-role"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
}

#Attaches the AWS managed policy AmazonEKSClusterPolicy to the cluster IAM role to grant necessary EKS permissions.
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}   


#-------------------------------------------
# IAM role for EKS worker nodes
#Creates an IAM role for the EC2 instances that make up the Kubernetes worker nodes.
#EC2 service is allowed to assume this role.

resource "aws_iam_role" "nodes" {
  name = "eks-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole" #allows EC2 instances to assume this role
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com" # Trusted entity is EC2 service
            }
        }
        ]
    })

    tags = {
        Name        = "eks-node-role"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }
  
}

# Allows node management of EKS resources
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

#Networking via the EKS CNI plugin.
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#Allows pulling container images from ECR
resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#-------------------------------------------
# IAM role for EBS CSI driver using Pod Identity
#Trust policy allows Kubernetes pods to assume the role using pod identity.
resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKSPodIdentityAmazonEBSCSIDriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "ebs-csi-driver-role"
    Environment = "dev"
    Project     = "eks-infrastructure"
    ManagedBy   = "terraform"
  }
}
#Grants permissions to the EBS CSI driver role for managing AWS EBS volumes.
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Associates the EBS CSI driver's Kubernetes service account with its IAM role.

#Enables the pod to assume the role securely using pod identity.
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = aws_eks_cluster.custom.name
  namespace       = "kube-system" #default namespace for the EBS CSI driver addon
  service_account = "ebs-csi-controller-sa" #default service account name for the EBS CSI driver addon
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}

#-------------------------------------------
#define managed node groups for the EKS cluster 
#Uses iteration to create multiple node groups from input variables.
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups  #can have multiple node groups with different instance types and scaling configs --scalable 
    cluster_name    = aws_eks_cluster.custom.name
    node_group_name = each.key 
    node_role_arn   = aws_iam_role.nodes.arn
    subnet_ids      = var.private_subnet_ids
    scaling_config {
        desired_size   = each.value.scaling_config.desired_capacity
        max_size     = each.value.scaling_config.max_size
        min_size     = each.value.scaling_config.min_size

    }
    disk_size = var.disk_size #disk size in GB for the worker nodes
    instance_types = each.value.instance_types

    tags = {
        Name        = "eks-node-group-${each.key}"
        Environment = "dev"
        Project     = "eks-infrastructure"
        ManagedBy   = "terraform"
    }

    depends_on = [aws_eks_cluster.custom]

}

#-------------------------------------------
#Addons for the EKS cluster
#EKS addons needed for networking (vpc-cni), service proxy (kube-proxy), DNS (coredns), monitoring (metrics-server), and IAM pod identity support.
resource "aws_eks_addon" "addons" {
  for_each     = toset(["vpc-cni", "kube-proxy", "coredns","metrics-server","eks-pod-identity-agent"])
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = each.value

  tags = {
    Name        = "eks-addon-${each.value}"
    Environment = "dev"
    Project     = "eks-infrastructure"
    ManagedBy   = "terraform"
  }
}

#ebs csi driver addon with pod identity association for dynamic provisioning of persistent volumes using EBS. 
#Is created sereate as it required pod identity association and extra access.
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "aws-ebs-csi-driver"

  tags = {
    Name        = "eks-addon-ebs-csi-driver"
    Environment = "dev"
    Project     = "eks-infrastructure"
    ManagedBy   = "terraform"
  }

  depends_on   = [aws_eks_pod_identity_association.ebs_csi]
}

#-------------------------------------------

#Grants standard access permissions to the AWS root user of the current account for cluster management in console & GitHub(runner).

resource "aws_eks_access_entry" "console_access" {
  cluster_name  = aws_eks_cluster.custom.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/july2025"
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.custom]
}

#Associates an admin access policy with the root user principal to grant full administrative rights on the cluster.

resource "aws_eks_access_policy_association" "console_admin" {
  cluster_name  = aws_eks_cluster.custom.name
  principal_arn = aws_eks_access_entry.console_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" #above policy is to create eks this is to access it.

  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.console_access]
}

# Data source to get dynamically current AWS account ID for provisioning console access
data "aws_caller_identity" "current" {}