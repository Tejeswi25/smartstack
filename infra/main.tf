# infra/main.tf

# 1. Spin up the network architecture, passing the security group output from our compute layer
module "network_layer" {
  source                     = "../modules/custom_vpc"
  vpc_name                   = "smartstack-${var.environment}-vpc"
  cidr_block                 = var.vpc_cidr
  cluster_name               = var.cluster_name
  eks_node_security_group_id = module.compute_layer.node_security_group_id # ◄ Feeds compute group backward
}

# 2. Spin up your compute layer, feeding forward the subnet IDs from your network layer
module "compute_layer" {
  source          = "../modules/custom_eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  
  vpc_id          = module.network_layer.vpc_id
  subnet_ids      = module.network_layer.private_subnets
}