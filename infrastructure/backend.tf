terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-oriya-hen-1"   
    key = "project/terraform.tfstate"  
    region = "us-east-2"                   
    dynamodb_table = "oriya-terraform-lock-table-1"        
    encrypt = true
    }
}
