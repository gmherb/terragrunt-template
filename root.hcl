# Root terragrunt.hcl file

########## BACKEND CONFIGURATION ##########
# Generate is the original way to configure the backend in Terragrunt. All backends are supported.
#
#generate "backend" {
#  path      = "backend.tf"
#  if_exists = "overwrite_terragrunt"
#  contents = <<EOF
#terraform {
#  backend "s3" {
#    bucket         = "my-tofu-state"
#    key            = "${path_relative_to_include()}/tofu.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "my-lock-table"
#  }
#}
#EOF
#}
#generate "backend" {
#  path      = "backend.tf"
#  if_exists = "overwrite_terragrunt"
#  contents = <<EOF
#terraform {
#  backend "gcs" {
#    bucket         = "my-tofu-state"
#    key            = "${path_relative_to_include()}/tofu.tfstate"
#  }
#}
#EOF
#}
#
# Terragrunt supports an additional remote_state configuration option that allows you to specify
# a non-existing bucket and Terragrunt will create it for you.
#
# This tries to solve the chicken and egg problem of having to create the bucket first before
# you can use it in the remote_state configuration.
#
# However, this is only supported for S3 and GCS backends.
#
#remote_state {
#  backend = "s3"
#  config = {
#    bucket         = "terraform-state"
#    key            = "terraform.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "terraform-state-lock"
#  }
#}
#remote_state {
#  backend = "gcs"
#  config = {
#    bucket         = "terraform-state"
#    key            = "terraform.tfstate"
#  }
#}
#
# For more information, see the Terragrunt documentation:
# https://terragrunt.gruntwork.io/docs/features/state-backend/

# For more granular control, you can add backend configuration in the environment terragrunt configuration file.
#
# Examples:
# dev/environment.hcl
# prod/environment.hcl
#
# This may be useful if:
# 1. you want to use a different backend for each environment
# 2. you want to prevent data leakage between environments
# 3. different teams are operating in different environments

########## INPUTS CONFIGURATION ##########
# Place inputs configuration here if you want to use the same inputs for all environments.
inputs = {
    company_name = "my-company"
}

########## ARGUMENTS CONFIGURATION ##########
# https://terragrunt.gruntwork.io/docs/features/extra-arguments/
#
# Each extra_arguments block includes an arbitrary label (in the example below, retry_lock),
# a list of commands to which the extra arguments should be added, and a list of arguments,
# required_var_files or optional_var_files to add.
#
# You can also pass custom environment variables using the env_vars attribute,
# which stores environment variables in key value pairs.
#
terraform {
  # Force OpenTofu/Terraform to keep trying to acquire a lock for
  # up to 20 minutes if someone else already has the lock
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()

    arguments = [
      "-lock-timeout=20m"
    ]

    env_vars = {
      TF_VAR_var_from_environment = "value"
    }
  }
}

########## CONDITIONAL VARIABLES CONFIGURATION ##########
# https://terragrunt.gruntwork.io/docs/features/extra-arguments/#required-and-optional-var-files
#
#terraform {
#  extra_arguments "conditional_vars" {
#    commands = [
#      "apply",
#      "plan",
#      "import",
#      "push",
#      "refresh"
#    ]
#
#    required_var_files = [
#      "${get_parent_terragrunt_dir()}/tofu.tfvars"
#    ]
#
#    optional_var_files = [
#      "${get_parent_terragrunt_dir("root")}/${get_env("TF_VAR_env", "dev")}.tfvars",
#      "${get_parent_terragrunt_dir("root")}/${get_env("TF_VAR_region", "us-east-1")}.tfvars",
#      "${get_terragrunt_dir()}/${get_env("TF_VAR_env", "dev")}.tfvars",
#      "${get_terragrunt_dir()}/${get_env("TF_VAR_region", "us-east-1")}.tfvars"
#    ]
#  }
