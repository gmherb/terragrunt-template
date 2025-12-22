# dev/environment.hcl

# place inputs here for development specific inputs
inputs = {
    environment = "development"
}

# place remote state here for development specific remote state
#remote_state = {
#  backend = "s3"
#  config = {
#    bucket         = "dev-terraform-state"
#    key            = "terraform.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "dev-terraform-state-lock"
#  }
#}
