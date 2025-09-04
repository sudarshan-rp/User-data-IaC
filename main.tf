

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "eks" {
  source = "./modules/eks"

  cluster_version    = var.cluster_version
  node_groups        = var.node_groups
  private_subnet_ids = module.vpc.private_subnet_ids
  depends_on         = [module.vpc]
}