output "primary_network_interface" {
  value = ibm_is_instance.compute.primary_network_interface[0].id
}

output "instance" {
  value = ibm_is_instance.compute[*]
}

# output "instance_id" {
#   value = ibm_is_instance.compute.id
# }