# prod/terragrunt.hcl

# place inputs here for production specific inputs
inputs = {
    environment = "production"
}

# place remote state here for production specific remote state
#remote_state = {
#  backend = "s3"
#  config = {
#    bucket         = "prod-terraform-state"
#    key            = "terraform.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "prod-terraform-state-lock"
#  }
#}
