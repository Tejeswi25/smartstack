module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Allows you to run kubectl from outside the VPC if needed, while keeping worker nodes isolated
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Enables IAM Roles for Service Accounts (IRSA)
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  # ====================================================================
  # COMPUTE NODE GROUP (Spot Pricing Optimization)
  # ====================================================================
  eks_managed_node_groups = {
    spot_workers = {
      min_size     = 1
      max_size     = 4
      desired_size = 2

      # Use EC2 Spot instances for significant cost savings
      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium"] # Diversified to reduce spot termination risk

      labels = {
        Environment = "production"
        Billing     = "spot"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
    }
  }
}