# ==========================================
# Network Infrastructure Variables
# ==========================================

variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed."
  default     = "ap-southeast-1" # Defaulted to Singapore
}

variable "cidr_block" {
  type        = string
  description = "The base CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

# ==========================================
# EKS Cluster Core Variables
# ==========================================

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
  default     = "production-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "The version of Kubernetes to deploy on the EKS cluster."
  default     = "1.33"
}

# ==========================================
# Security & Computing Variables
# ==========================================

variable "eks_node_security_group_id" {
  type        = string
  description = "The ID of an existing security group to attach to the EKS worker nodes. Commonly used to allow endpoint traffic."
  default     = "" # If creating a fresh cluster, you can override this with the module's output later
}

variable "node_root_volume_size" {
  type        = number
  description = "The size of the root EBS volume for worker nodes in gigabytes."
  default     = 20 # Minimum base, scale up to 50+ for heavy container workloads
}

variable "node_root_volume_type" {
  type        = string
  description = "The EBS volume type for the worker nodes."
  default     = "gp3"
}

# ==========================================
# Cluster Access & Identification Tags
# ==========================================

variable "environment" {
  type        = string
  description = "The deployment environment name used for resource tagging."
  default     = "production"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}