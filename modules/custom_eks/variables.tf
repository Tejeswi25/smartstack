variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  default     = "1.33"
  description = "The target Kubernetes version for the EKS control plane"
}

variable "vpc_id" {
  type        = string
  description = "The target VPC ID where EKS components will be provisioned"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of private subnet IDs where the worker nodes will live"
}