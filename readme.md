smartstack/
│
├── .github/
│   └── workflows/
│       ├── infra-pipeline.yml   # ◄ Pipeline 1: Provisions VPC & EKS via Terraform
│       └── app-pipeline.yml     # ◄ Pipeline 2: Builds Docker, pushes to ECR, deploys via Helm
│
├── api/
│   ├── app.py                  # ◄ Your Python Flask API code
│   ├── requirements.txt        # ◄ Python dependencies (Flask, redis, psycopg2)
│   └── Dockerfile              # ◄ How to containerize your API
│
├── charts/
│   └── core-app/               # ◄ Your Helm chart directory
│       ├── Chart.yaml
│       ├── values.yaml         # ◄ Overridden dynamically by app-pipeline.yml
│       └── templates/
│           ├── api-deployment.yaml
│           ├── cache-deployment.yaml
│           └── db-deployment.yaml
│
└── smartstack/
├── infra/                      # ◄ Your Root Workspace
│   ├── provider.tf
│   ├── main.tf                 # ◄ Instantiates your custom modules
│   ├── outputs.tf
│   └── terraform.tfvars
└── modules/                    # ◄ Your Custom Modules Library
    ├── custom_vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── custom_eks/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf