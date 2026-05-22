terraform {
    required_version = ">= 1.5.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }


# Configure standard remote state management

    backend "s3" {
        bucket         = "smartstack-tf-state-bucket" #change to the bucket name
        key            = "environments/production/terraform.tfstate"
        region         = "ap-southeast-1"
        encrypt        = true
    }
}

# Configure the default AWS Provider targeting Singapore region
provider "aws" {
    region = var.aws_region
}