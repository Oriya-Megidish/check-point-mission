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
| `KMS_ADMIN_ROLE_ARN ` | ARN of the role with permissions to manage kms keys| `arn:aws:iam::123456789012:role/kms_admin` |
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
| `TF_STATE_BUCKET` | Bucket for statefile | `terraform-state-bucket-oriya` |
| `TF_STATE_LOCK_TABLE` |DynamoDB for locking statefile | `terraform-lock-table-oriya` |

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
       region = "us-east-2"
     }
     ```

   - Create `backend.tf`:

     ```hcl
     terraform {
       backend "s3" {
         bucket         = "my-tf-state-bucket"
         key            = "infrastructure/terraform.tfstate"
         region         = "us-east-2"
         dynamodb_table = "my-lock-table"
         encrypt        = true
       }
     }
     ```

   > **Note**: You must use the same S3 bucket, DynamoDB table and aws region as configure in step 1`:
   >

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

You can test Terraform changes locally via:

```bash
cd infrastructure/
terraform init
terraform validate
terraform plan 
terraform apply 
```

---

## Accessing the Application

After the pipeline runs and completes successfully, you can access the application by sending a POST request using curl:

```bash
curl -X POST http://<ALB_DNS_NAME>:5000/ \
     -H "Content-Type: application/json" \
     -d @message.json
```

Where the message.json file should contain a valid JSON payload in the following format:

```json
{
  "data": {
    "email_subject": "Happy new year!",
    "email_sender": "John Doe",
    "email_timestream": "1693561101",
    "email_content": "Just want to say... Happy new year!!!"
  },
  "token": "$DJISA<$#45ex3RtYr"
}
```

### Important Notes

- The token field must match the value you configured in SSM Parameter Store during deployment.
- The email_timestream field must be in *Unix time format* (i.e. seconds since epoch).

If the request is valid and accepted, the response will be:

```json
{
  "MessageId": "df89f5fb-ca1f-4853-ad80-ef5378cbedb4",
  "message": "Payload forwarded to SQS"
}
```

---

### Handling Time Errors

If you receive an error stating that 'email_timestream' is outside the allowed 5-minute window, you can retrieve the current Unix timestamp from the running ECS task:

```bash
curl -X GET http://<ALB_DNS_NAME>/time
```

Use the timestamp returned in the email_timestream field of your payload.

---

- The *SQL Listener service* (the second ECS service)
will:
- Listen to the same SQS queue.
- Retrieve the message.
- Upload the message to the S3 bucket created via
Terraform.
- Delete the message from the queue.


- This CI/CD setup uses Terraform caching to speed up provider/module downloads and Docker layer caching for faster builds.
