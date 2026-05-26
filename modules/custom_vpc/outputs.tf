output "vpc_id" {
    value = module.vpc.vpc_id 
    description = "The unique ID assigned to the new VPC workspace network"
}

output "private_subnets" {
    value = module.vpc.private_subnets
    description = "A collection list containing the generated private subnet IDs"
}

output "public_subnets" {
    value = module.vpc.public_subnets
    description = "A list containing the generated public subnet IDs"
}