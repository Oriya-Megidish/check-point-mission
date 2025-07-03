terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-oriya-hen"   
    key = "project/terraform.tfstate"  
    region = "us-east-2"                   
    dynamodb_table = "oriya-terraform-lock-table"        
    encrypt = true
    profile = "oriya"
    }
}