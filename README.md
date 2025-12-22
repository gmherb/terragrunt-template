# terragrunt-template

Terragrunt template for Infrastructure as Code (IaC)

## find_in_parent_folders

If no name is provided, find_in_parent_folders searches for terragrunt.hcl in the parent directories.

https://terragrunt.gruntwork.io/docs/features/includes/

## Layout

This layout starts with a space for development and production. Add more environments as needed.

    $ tree -L 3
    .
    ├── dev
    │   ├── environment.hcl       / dev configuration
    │   └── foo
    │       └── terragrunt.hcl    / dev foo deployment
    ├── _env
    │   ├── example
    │   │   └── common.hcl        / common configurations for example module
    │   └── _version
    │       └── example.hcl       / module versioning for example module
    ├── Makefile
    ├── modules
    │   └── example
    │       └── main.tf
    ├── prod
    │   └── environment.hcl       / prod configuration
    ├── README.md
    └── root.hcl                  / root configuration

- `_env`: Common environment used to define things once and include in multiple environments.
- `dev`: The development environment.
- `prod`: The production environment.
