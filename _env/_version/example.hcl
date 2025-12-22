# Set the source here for example module to be included in all units
# This provides a single place to update the module version
# without having to update each unit individually.
#
# At any time, you can update a single unit by not including this
# terragrunt configuration and defining the source and version required
#
terraform {
  #source = "git::ssh://git@github.com/example/example.git?ref=v1.0.0"
  source = "../../modules/example"
}

# Set the module version for the example module to be used in tracking purposes.
# Does not affect the module itself.
inputs = {
  module_version = "v1.0.0"
}