locals {
  tfvars = jsondecode(read_tfvars_file("terraform.tfvars"))
}

remote_state {
  backend = "gcs"
  config = {
    bucket      = local.tfvars.gcs_state_bucket
    prefix      = "openshift/${local.tfvars.region}/${local.tfvars.name}/terraform.tfstate"
    credentials = local.tfvars.credential_file
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
