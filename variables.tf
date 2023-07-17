variable "existing_resource_group" {
  description = "Name of an existing Resource Group to use for resources. If not set, a new Resource Group will be created."
  type        = string
}

variable "region" {
  description = "IBM Cloud region where resources will be deployed"
  type        = string
}

variable "existing_ssh_key" {
  description = "Name of an existing SSH key in the region. If not set, a new SSH key will be created."
  type        = string
}

variable "classic_access" {
  description = "Allow classic access to the VPC."
  type        = bool
  default     = false
}

variable "default_address_prefix" {
  description = "The address prefix to use for the VPC. Default is set to auto."
  type        = string
  default     = "auto"
}

variable "instance_count" {
  description = "The number of instances to create"
  type        = number
  default     = 2
}

variable "owner" {
  description = "The owner of the resources, used as a tag."
  type        = string
}

variable "frontend_rules" {
  description = "A list of security group rules to be added to the Frontend security group"
  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"] :
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

  default = [
    {
      name       = "inbound-http"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "inbound-https"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "inbound-ssh"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name       = "inbound-icmp"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      icmp = {
        code = 0
        type = 8
      }
    },
    {
      name       = "microk8s-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 25000
        port_max = 25000
      }
    },
    {
      name       = "microk8s-api-inbound"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 16443
        port_max = 16443
      }
    },
    {
      name       = "all-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
    }
  ]
}

