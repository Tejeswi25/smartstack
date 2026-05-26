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
  public_key = "sh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWTHk1cDN4pDhzjUek5rQn+43Fs5lKbN1IYmPLHSik2sDq2glWldYqtuXmML/tvkjsHTuyrJMJmNBGUtKxB8qUOceEqPh27/1OW9b7PUC3SO8gJD0DXOHJwZYdt6MS9XupQjGSglxsSyuNKzZEed6Nfzz2bqW4f4VIxEhGo8T9zjUiji3xgCOdhdKvnTN52nnyRLaNsHB9fgpwSAj4n4Uf3D6/3Rid+dscURcWkyIXCyTeve0lU+3xsxbxNbT3liJ/LUPohH+dlb62+4WrBG5JMzdLUn4wjH6pS7engz8tHU0qmdsnkOrFBNp1n/1iSUXlZJ9f6dm3w/aSDyxPHr87ziXKSWajUi/wanJCKhsycrj5iDm2F8YLglCl77bF8ZBhCc5Mt0iN0j7T4I0LsbsmqinqRh4fEctVhqiAd/8seYzpD/g8mEadryuuzg79tJYoe1g1BG7XKeq8DeoMXu48AthEHjas8LCOkDXjLnRk3ZQaX3J70xsAx9wVrBUMf60= pteju@LAPTOP-S3M8EN72
"
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
  key_name                    = "aws_key_pair.deployer.key_name"

  # Dynamically fetch the first public subnet ID created by your VPC module
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

  # Automatically assign a public IP address so you can connect to it over the internet
  associate_public_ip_address = true
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