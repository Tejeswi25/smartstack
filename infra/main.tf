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
# -----------------------------------------------------------------
# Security Group for Public Jump Box / Bastion Host
# -----------------------------------------------------------------
resource "aws_security_group" "jumpbox_sg" {
  name        = "jumpbox-vm-sg"
  description = "Allow inbound SSH or administrative access to the jump box"
  vpc_id      = module.network_layer.vpc_id

  # Inbound rule: Adjust cidr_blocks to your home/office public IP for tight security
  ingress {
    description = "Allow SSH from anywhere (Change to your specific IP for security!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Outbound rule: Allows the instance to pull package updates or tools from the web
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jumpbox-vm"
  }
}

# IAM Identity setup
resource "aws_iam_role" "jumpbox_role" {
  name = "jumpbox-eks-admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com"}
      }
    ]
  })
}

# Attach core SSM policy as a backup connection method
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role = aws_iam_role.jumpbox_role.name 
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_key_pair" "deployer" {
  key_name = "my-new-ssh-key"
  public_key = file("${path.module}/id_rsa.pub")
}
# -----------------------------------------------------------------
# EC2 Instance Deployment Module
# -----------------------------------------------------------------
module "ec2_jumpbox" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "jumpbox-vm"

  instance_type          = "t3.micro" # Lightweight, cost-effective for a jump box

  associate_public_ip_address = true 
  key_name                    = aws_key_pair.deployer.key_name

  # Dynamically fetch the first public subnet ID created by your VPC module
  subnet_id              = module.network_layer.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]


  # Automatically installs kubectl,helm and AWS CLI
  user_data = <<-EOT
    #! /bin/bash
    sudo apt-get update -y
    sudo apt-get install -y unzip curl git

    # 1. Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # 2. Install kubectl 
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # 3. Install Helm v3
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  EOT

  tags = {
    Environment = "production"
    Role        = "bastion-jumpbox"
  }
}

resource "aws_security_group_rule" "allow_jumpbox_to_eks" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = module.compute.node_security_group_id
  source_security_group_id = resource.aws_security_group.jumpbox_sg.id
  description = "Allow kubectl traffic from admin jump box"
}