output "cluster_name" {
  description = "The name of the generated EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint URL for your Kubernetes API server connection"
  value       = module.eks.cluster_endpoint
}

output "node_security_group_id" {
  description = "The automatically generated security group ID governing the EKS worker nodes"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OpenID Connect identity provider for IAM Service Accounts mapping"
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}