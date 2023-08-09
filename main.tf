locals {
  prefix      = random_string.prefix.result
  ssh_key_ids = var.existing_ssh_key != "" ? [data.ibm_is_ssh_key.sshkey[0].id] : [ibm_is_ssh_key.generated_key[0].id]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }

  frontend_rules = [
    for r in var.frontend_rules : {
      name       = r.name
      direction  = r.direction
      remote     = lookup(r, "remote", null)
      ip_version = lookup(r, "ip_version", null)
      icmp       = lookup(r, "icmp", null)
      tcp        = lookup(r, "tcp", null)
      udp        = lookup(r, "udp", null)
    }
  ]

  tags = [
    "provider:ibm",
    "workspace:${terraform.workspace}",
    "owner:${var.owner}"
  ]
}

# IF a resource group was not provided, create a new one
module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.6"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

# Generate a random string if a project prefix was not provided
resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

# Generate a new SSH key if one was not provided
resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Add a new SSH key to the region if one was created
resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.0.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

# Write private key to file if it was generated
resource "null_resource" "create_private_key" {
  count = var.existing_ssh_key != "" ? 0 : 1
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.ssh.0.private_key_pem}' > ./'${local.prefix}'.pem
      chmod 400 ./'${local.prefix}'.pem
    EOT
  }
}

module "vpc" {
  source                      = "terraform-ibm-modules/vpc/ibm//modules/vpc"
  version                     = "1.1.1"
  create_vpc                  = true
  vpc_name                    = "${local.prefix}-vpc"
  resource_group_id           = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  default_address_prefix      = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  vpc_tags                    = local.tags
  locations                   = [local.vpc_zones[0].zone, local.vpc_zones[1].zone, local.vpc_zones[2].zone]
  number_of_addresses         = "128"
  create_gateway              = true
  subnet_name                 = "${local.prefix}-frontend-subnet"
  public_gateway_name         = "${local.prefix}-pub-gw"
  gateway_tags                = local.tags
}

module "security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = module.vpc.vpc_id[0]
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.frontend_rules
}

module "bastion" {
  source            = "./modules/compute"
  prefix            = "${local.prefix}-bastion"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = module.vpc.vpc_id[0]
  subnet_id         = module.vpc.subnet_ids[0]
  security_group_id = module.security_group.security_group_id[0]
  zone              = local.vpc_zones[0].zone
  ssh_key_ids       = local.ssh_key_ids
  tags              = local.tags
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-${local.vpc_zones[0].zone}-bastion-ip"
  target         = module.bastion.primary_network_interface
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

module "controllers" {
  count             = var.controller_count
  source            = "./modules/compute"
  prefix            = "${local.prefix}-controller-${count.index}"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = module.vpc.vpc_id[0]
  subnet_id         = module.vpc.subnet_ids[0]
  security_group_id = module.security_group.security_group_id[0]
  zone              = local.vpc_zones[0].zone
  ssh_key_ids       = local.ssh_key_ids
  tags              = local.tags
}

module "workers" {
  count             = var.worker_count
  source            = "./modules/compute"
  prefix            = "${local.prefix}-worker-${count.index}"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = module.vpc.vpc_id[0]
  subnet_id         = module.vpc.subnet_ids[0]
  security_group_id = module.security_group.security_group_id[0]
  zone              = local.vpc_zones[0].zone
  ssh_key_ids       = local.ssh_key_ids
  tags              = local.tags
}

module "ansible" {
  source            = "./ansible"
  bastion_public_ip = ibm_is_floating_ip.bastion.address
  controller        = module.controllers[*].instance[0]
  workers           = module.workers[*].instance[0]
  deployment_prefix = local.prefix
  region            = var.region
}