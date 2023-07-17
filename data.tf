data "ibm_is_ssh_key" "sshkey" {
  count = var.existing_ssh_key != "" ? 1 : 0
  name  = var.existing_ssh_key
}

# Pull in the zones in the region
data "ibm_is_zones" "regional" {
  region = var.region
}

data "ibm_resource_instance" "cos" {
  count = var.existing_cos_instance != "" ? 1 : 0
  name  = var.existing_cos_instance
}
