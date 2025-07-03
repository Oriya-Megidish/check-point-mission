# ECS Microservices Infrastructure Deployment (Terraform + GitHub Actions)

This project provisions and manages an ECS-based microservices architecture on AWS using Terraform and GitHub Actions CI/CD. It supports fully automated deployment, image pushing, and service updates with clean modular code structure.

---

## Prerequisites - Installation

Before you start, make sure you have installed the following tools on your local machine:

- **Node.js** – required for aws cli
- **AWS CLI** 
- **Terraform** 
- **Git** 

---

## Required GitHub Secrets

Before triggering the pipeline, ensure that these secrets are configured in your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `ACCOUNT_ID` | Your AWS account ID | `123456789012` |
| `ADMIN_ROLE_ARN` | ARN of the role with administrative permissions | `arn:aws:iam::123456789012:role/Admin` |
| `AWS_ACCESS_KEY_ID` | IAM user access key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | `wJalrXUtnFEMI/K7MDENG...` |
| `AWS_REGION` | AWS region | `us-east-2` |
| `TOKEN_PARAMETER` | Name of SSM SecureString parameter | `/app/token` |
| `TOKEN_VALUE` | Actual token value for the app | `secret1234` |
| `ECR_SQL_LISTENER_REPO_URI` | Full URI of the ECR repo for the SQL Listener | `123456789012.dkr.ecr.us-east-1.amazonaws.com/sql-listener` |
| `ECR_REST_SERVICE_REPO_URI` | Full URI of the ECR repo for the REST Service | `123456789012.dkr.ecr.us-east-1.amazonaws.com/rest-service` |
| `OWNER` | Project owner tag for naming resources | `oriya` |
| `REST_SERVICE_NAME` | ECS service name for REST app | `rest-service` |
| `SQL_LISTENER_SERVICE_NAME` | ECS service name for SQL Listener | `sql-listener` |

---

## How to Deploy

1. **Set up GitHub Secrets** as described above.

2. **Clone the repository**:

   ```bash
   git clone https://github.com/your-org/your-repo.git
   cd your-repo
   ```

3. **Configure Terraform backend and provider**:

   In the `infrastructure/` folder:

   - Create `provider.tf`:

     ```hcl
     provider "aws" {
       region = var.aws_region
     }
     ```

   - Create `backend.tf`:

     ```hcl
     terraform {
       backend "s3" {
         bucket         = "my-tf-state-bucket"
         key            = "infrastructure/terraform.tfstate"
         region         = "us-east-1"
         dynamodb_table = "my-lock-table"
         encrypt        = true
       }
     }
     ```

   > **Note**: You must create the S3 bucket and DynamoDB table manually before running `terraform init`:
   >
   > ```bash
   > aws s3api create-bucket --bucket my-tf-state-bucket --region us-east-2
   >
   > aws dynamodb create-table \
   >   --table-name my-lock-table \
   >   --attribute-definitions AttributeName=LockID,AttributeType=S \
   >   --key-schema AttributeName=LockID,KeyType=HASH \
   >   --billing-mode PAY_PER_REQUEST
   > ```

4. **Edit image settings if needed**:

   **Note**: These values should match the secrets configured in Step 1.
   Go to `infrastructure/locals.tf` and update image tag/repo names:

   ```hcl
   rest_repo_name        = "rest-service"
   rest_version          = "latest"
   sql_listener_repo_name = "sql-listener"
   sql_listener_version   = "latest"
   ```

5. **Push to main branch**:

   ```bash
   git add .
   git commit -m "Trigger deployment"
   git push origin main
   ```

---

## What the Pipeline Does

1. **Terraform**:
   - Initializes and applies all infrastructure via `terraform apply`
   - Resources include: VPC, ECS cluster, IAM roles, security groups, ALB, endpoints, ECR, CloudWatch, SQS, S3, and KMS.

2. **Tests**:
   - Installs dependencies and runs tests (optional – currently placeholder).

3. **Build and Push**:
   - Builds Docker images for `rest_service` and `sql_listener`
   - Pushes images to the corresponding ECR repos

4. **Deployment**:
   - Calls `aws ecs update-service --force-new-deployment` to update both ECS services

---


## Notes

- You can test Terraform changes locally via:

  ```bash
  cd infrastructure/
  terraform init
  terraform validate
  terraform plan 
  terraform apply 
  ```

- This CI/CD setup uses Terraform caching to speed up provider/module downloads and Docker layer caching for faster builds.
