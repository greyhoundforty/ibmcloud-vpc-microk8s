resource "local_file" "ansible-inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl",
    {
      controller = var.controller
      bastion_ip = var.bastion_public_ip
      workers    = var.workers
    }
  )
  filename = "${path.module}/inventory.ini"
}
