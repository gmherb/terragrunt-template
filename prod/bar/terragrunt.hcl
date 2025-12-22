# Include the root terragrunt configuration file
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the environment configuration
include "environment" {
  path           = find_in_parent_folders("environment.hcl")
  merge_strategy = "deep"
}

# Include the default version for the example module
include "version" {
  path           = find_in_parent_folders("_env/_version/example.hcl")
  merge_strategy = "deep"
}

# Include the common inputs for the example module
include "common" {
  path           = find_in_parent_folders("_env/example/common.hcl")
  merge_strategy = "deep"
}

# Deployment specific inputs
inputs = {
  deployment_name = "bar"
}
