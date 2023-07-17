resource "local_file" "ansible-inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl",
    {
      instances  = var.instances
      bastion_ip = var.bastion_public_ip
    }
  )
  filename = "${path.module}/inventory.ini"
}
