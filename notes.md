name: "2. Application Build & Helm Release"

on:
  push:
    branches:
      - main
    paths:
      - 'api/**'
      - 'charts/**'
      - '.github/workflows/app-pipeline.yml'

jobs:
  build-and-deploy:
    name: "CI/CD App Stack"
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-1

      # 1. AUTHENTICATE TO ECR
      - name: Log in to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # 2. BUILD, TAG AND PUSH IMAGE
      - name: Build and Push Docker Image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: smartstack/api
          IMAGE_TAG: ${{ github.sha }} # Use immutable short commit hash as the tag
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG ./api
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "IMAGE_URI=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_ENV

      # 3. CONFIGURE KUBECTL CONTEXT FOR EKS
      - name: Connect to EKS Cluster
        run: |
          aws eks update-kubeconfig --region ap-southeast-1 --name smartstack-production-eks

      # 4. INSTALL HELM
      - name: Setup Helm
        uses: azure/setup-helm@v4
        with:
          version: 'v3.12.0'

      # 5. UPGRADE/INSTALL WORKLOAD WITH DYNAMIC VALUE OVERRIDES
      - name: Deploy Application via Helm
        run: |
          helm upgrade --install smartstack-core ./charts/core-app \
            --namespace default \
            --set api.image.repository=${{ steps.login-ecr.outputs.registry }}/smartstack/api \
            --set api.image.tag=${{ github.sha }}
=================================================================================
