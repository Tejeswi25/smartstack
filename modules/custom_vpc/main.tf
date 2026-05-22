 # Discover available availabilty zones automatically

# Discover available availability zones dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# Core VPC construction
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.cidr_block

  # Fix layout to exactly 2 AZs, splitting into 1 Public and 2 Private subnets
  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets = [cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  public_subnets  = [cidrsubnet(var.cidr_block, 8, 101)]

  # Turn off expensive native AWS NAT Gateways completely
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
    vpc_id = module.vpc.vpc_id
    service_name = "com.amazonaws.ap-southeast-1.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids = module.vpc.private_route_table_ids
}

# 2. ECR API Interface Endpoint (Handles auth and repository manifests)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [var.eks_node_security_group_id]
}

# 3. ECR Docker Interface Endpoint (Handles the actual docker pull layer binary streams)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [var.eks_node_security_group_id]
}

# 4. EC2 API Endpoint (Crucial: Required by the EKS nodes to join the cluster without a NAT)
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [var.eks_node_security_group_id]
}

