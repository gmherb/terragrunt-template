# Example module
#
# Modules should be in their own repository for most reusability.
# This helps enforce separation of deployments from the actual infrastructure as code.
#
# Modules should be referenced by their repository URL and version.
#
# module "example" {
#   source = "github.com/my-company/terraform-module-example.git?ref=v1.0.0"
# }
#

variable "environment" {
  description = "The environment"
  type        = string
}

variable "domain" {
  description = "The domain"
  type        = string
}

variable "deployment_name" {
  description = "The deployment name"
  type        = string
}

variable "module_version" {
  description = "The module version for tracking purposes. Does not affect the module itself."
  type        = string
}

locals {
  example_output = "${var.domain}-${var.environment}-${var.deployment_name}-${var.module_version}"
}

resource "null_resource" "this" {
  triggers = {
    environment     = var.environment
    domain          = var.domain
    deployment_name = var.deployment_name
    module_version  = var.module_version
  }
}

resource "local_file" "this" {
  content = local.example_output
  filename = "${local.example_output}.txt"

  lifecycle {
    replace_triggered_by = [
      null_resource.this
    ]
  }
}

output "example_output" {
  value = local.example_output
}
