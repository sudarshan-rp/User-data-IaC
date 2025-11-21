# 🚀 User-data-IaC

[![Terraform](https://img.shields.io/badge/Terraform-1.5.7+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI/CD-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Infrastructure as Code for deploying AWS EKS cluster with VPC using Terraform and GitHub Actions. This project provides a production-ready, secure, and cost-optimized EKS deployment with automated CI/CD pipeline.

## 📁 Project Structure

```
User-data-IaC/
├── .github/
│   └── workflows/
│       └── eks-setup.yml          # GitHub Actions CI/CD pipeline
├── modules/
│   ├── eks/
│   │   ├── main.tf                # EKS cluster, node groups, addons
│   │   ├── variable.tf            # EKS module variables
│   │   └── output.tf              # EKS module outputs
│   └── vpc/
│       ├── main.tf                # VPC, subnets, gateways, routes
│       ├── variable.tf            # VPC module variables
│       └── output.tf              # VPC module outputs
├── main.tf                        # Root module configuration
├── provider.tf                    # Terraform and AWS provider config
├── variable.tf                    # Root variables with defaults
├── output.tf                      # Root outputs
├── .gitignore                     # Git ignore patterns
├── .terraform.lock.hcl            # Terraform dependency lock
├── LICENSE                        # MIT License
└── README.md                      # This file give the brief of proj.
```

## 🏗️ Architecture Overview

### Infrastructure Components

- **🌐 VPC Module**: Creates isolated network with public/private subnets across 2 AZs as HA
- **☸️ EKS Module**: Deploys managed Kubernetes cluster with worker nodes and essential addons
- **🔄 GitHub Actions**: Automated deployment pipeline with proper error handling
- **🔒 Security**: IAM roles, access entries, and encrypted state management

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────┬───────────────────────────────────┤
│    us-east-1a           │           us-east-1b              │
├─────────────────────────┼───────────────────────────────────┤
│ Public Subnet           │ Public Subnet                     │
│ 10.0.3.0/24             │ 10.0.4.0/24                       │
│ ┌─────────────────────┐ │ ┌─────────────────────────────────┐ │
│ │   NAT Gateway       │ │ │        NAT Gateway              │ │
│ └─────────────────────┘ │ └─────────────────────────────────┘ │
├─────────────────────────┼───────────────────────────────────┤
│ Private Subnet          │ Private Subnet                    │
│ 10.0.1.0/24             │ 10.0.2.0/24                       │
│ ┌─────────────────────┐ │ ┌─────────────────────────────────┐ │
│ │  EKS Worker Nodes   │ │ │     EKS Worker Nodes            │ │
│ └─────────────────────┘ │ └─────────────────────────────────┘ │
└─────────────────────────┴───────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.7
- GitHub repository with Actions enabled
- S3 bucket for Terraform state storage
- DynamoDB table for state locking

### 1. Clone Repository

```bash
git clone https://github.com/your-username/User-data-IaC.git
cd User-data-IaC
```

### 2. Configure GitHub Secrets

Navigate to your repository → Settings → Secrets and variables → Actions, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `BUCKET_TF_STATE` | S3 bucket for state | `my-terraform-state-bucket` |

### 3. Deploy Infrastructure

#### Option A: GitHub Actions (Recommended)
1. Go to **Actions** tab in your repository
2. Select **eks_setup** workflow
3. Click **Run workflow**
4. Choose **create-cluster** action and required **branch**

#### Option B: Local Deployment
```bash
# Initialize Terraform
terraform init -backend-config="bucket=your-terraform-state-bucket"

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

### 4. Access Your Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name custom-eks

# Verify connection
kubectl get nodes
```

## ⚙️ Configuration

### Default Configuration

| Component | Default Value | Description |
|-----------|---------------|-------------|
| **Region** | `us-east-1` | AWS region |
| **VPC CIDR** | `10.0.0.0/16` | VPC IP range |
| **EKS Version** | `1.33` | Kubernetes version |
| **Node Instance** | `t3.small` | EC2 instance type |
| **Node Count** | `2` (min: 2, max: 3) | Worker nodes |
| **Disk Size** | `20 GB` | EBS volume size |

### Customization

Create `terraform.tfvars` file:

```hcl
# Network Configuration
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]

# EKS Configuration
cluster_version = "1.33"
node_groups = {
  general = {
    instance_types = ["t3.small"]
    scaling_config = {
      desired_capacity = 3
      min_size         = 2
      max_size         = 5
    }
  }
}
```

## 📦 Resources Created

### VPC Module Resources
- ✅ 1 VPC with DNS support
- ✅ 2 Public subnets (multi-AZ)
- ✅ 2 Private subnets (multi-AZ)
- ✅ 1 Internet Gateway
- ✅ 2 NAT Gateways (high availability)
- ✅ Route tables and associations
- ✅ Elastic IPs for NAT Gateways

### EKS Module Resources
- ✅ EKS Cluster with API endpoint
- ✅ Managed node group with auto-scaling
- ✅ Essential addons (VPC CNI, kube-proxy, CoreDNS, EBS CSI)
- ✅ IAM roles and policies
- ✅ Access entries for cluster management
- ✅ Security groups (managed by EKS)

## 🔒 Security Features

- **🔐 Private Worker Nodes**: All worker nodes in private subnets
- **🛡️ IAM Access Control**: Proper IAM roles and policies
- **🔑 Access Entries**: Modern EKS access management
- **🗄️ Encrypted State**: S3 backend with encryption
- **🔒 State Locking**: DynamoDB prevents concurrent modifications
- **📋 Least Privilege**: Minimal required permissions

## 💰 Cost Optimization

- **💡 Right-sized Instances**: t3.small for development workloads
- **📈 Auto Scaling**: Automatic node scaling based on demand
- **🌐 Managed Services**: Reduces operational overhead
- **⚡ Spot Instances**: Can be configured for non-production workloads

### Estimated Monthly Costs (us-east-1)
- EKS Cluster: ~$73/month
- 2x t3.small nodes: ~$30/month
- 2x NAT Gateways: ~$90/month
- **Total**: ~$193/month

> 💡 **Cost Tip**: Use single NAT Gateway for development to save ~$45/month

## 🔧 Advanced Configuration

### Adding Spot Instances

```hcl
node_groups = {
  spot = {
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    scaling_config = {
      desired_capacity = 1
      min_size         = 1
      max_size         = 10
    }
  }
}
```

### Custom Addons

```hcl
# Add AWS Load Balancer Controller
resource "aws_eks_addon" "aws_load_balancer_controller" {
  cluster_name = aws_eks_cluster.custom.name
  addon_name   = "aws-load-balancer-controller"
}
```

## 🔍 Monitoring & Observability

### CloudWatch Integration
```bash
# Enable CloudWatch logging
aws eks update-cluster-config \
  --name custom-eks \
  --logging '{"enable":["api","audit","authenticator","controllerManager","scheduler"]}'
```

### Useful Commands

```bash
# Check cluster status
kubectl get nodes -o wide

# View system pods
kubectl get pods -n kube-system

# Check addon status
aws eks describe-addon --cluster-name custom-eks --addon-name vpc-cni
```

### Testing / accesssing application

After deploying application in eks, to access it from service as NodePort in case of LoadBalancer use the below steps:
(If deployed as LB service then we can access application using the DNS provided by LB)

Start a debug pod with curl installed
Run a temporary pod with curl tool (example uses curlimages/curl image):

kubectl run -i --tty curlpod --image=curlimages/curl --restart=Never -- sh

This gives you a shell prompt inside the pod.
Curl your service inside cluster
Use the service name and port, for example:

curl http://backend-service.myapp.svc.cluster.local:8008/docs

O/P would be the HTTP in CLI which confirms the app running.

## 🚨 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Access Denied** | Verify IAM permissions and access entries |
| **Timeout Errors** | Check VPC configuration and security groups |
|**EBS not Bounding**| When the pvc is applied it usually will be in pending state due to missing permission |
| **State Lock** | Verify DynamoDB table exists and is accessible |
| **Node Join Issues** | Check subnet routing and security groups |

### Debug Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify EKS cluster
aws eks describe-cluster --name custom-eks

# Check node group status
aws eks describe-nodegroup --cluster-name custom-eks --nodegroup-name general
```

## 🧹 Cleanup

### Via GitHub Actions
1. Go to **Actions** tab
2. Run **eks_setup** workflow
3. Select **delete-cluster** action

### Via CLI
```bash
terraform destroy
```

##Updates implimented on 21//11

Performance:
• ✅ Parallel security scans using matrix strategy
• ✅ Terraform caching for faster subsequent runs
• ✅ Conditional plan step (only for create-cluster)
• ✅ Removed duplicate format step

Reliability:
• ✅ Timeouts: 15min for security, 30min for terraform
• ✅ Improved error handling with case statement
• ✅ Updated action versions: checkout@v4, setup-terraform@v3, configure-aws-credentials@v4
• ✅ Latest Terraform version: 1.9.8

Security:
• ✅ Both SARIF uploads for centralized security reporting


## 📚 Additional Resources

### Official Documentation
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Best Practices
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Tools & Extensions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [eksctl](https://eksctl.io/) - EKS CLI tool
- [k9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [minikube](https://minikube.sigs.k8s.io/docs/) - Running k8s locally 

### Community
- [AWS EKS Roadmap](https://github.com/aws/containers-roadmap)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core/)
- [Kubernetes Slack](https://kubernetes.slack.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📧 Email: sudarshanrpgowda7@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/sudarshan-rp/User-data-IaC/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/sudarshan-rp/User-data-IaC/discussions)

---

⭐ **Star this repository if it helped you!**
