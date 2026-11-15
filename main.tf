
# Find the catalog containing the Ubuntu vApp template
data "vcd_catalog" "ubuntu_catalog" {
  org  = "COT-1"
  name = "Eslam"
}

# Find the Ubuntu 22 template
data "vcd_catalog_vapp_template" "ubuntu" {
  org        = "COT-1"
  catalog_id = data.vcd_catalog.ubuntu_catalog.id
  name       = "Ubuntu-25-10-live-server"
}


locals {
  ansible_pubkey = trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
}
# Create VMs inside the existing NDM vApp

######################nagios#################################################
resource "vcd_vapp_vm" "nagios" {
  org                 = "COT-1"
  vdc                 = "K8s"
  vapp_name           = "NDM"
  name                = "nagios"
  computer_name       = "nagios"
  vapp_template_id    = data.vcd_catalog_vapp_template.ubuntu.id
  vm_name_in_template = "Ubuntu-25-10-l"

  # CPU: 2 sockets, 1 core per socket
  cpus      = 2
  cpu_cores = 1

  # Memory: 2 GB (MB)
  memory = 2048

  customization {
    force                      = false
    enabled                    = true
    allow_local_admin_password = true
    auto_generate_password     = false
    admin_password             = "***********"

    initscript = <<-EOT
      #!/bin/bash
      [ "$1" = "postcustomization" ] || exit 0
      hostnamectl set-hostname nagios
      sed -i '/# vprofile-begin/,/# vprofile-end/d' /etc/hosts
      printf '%s\n' '# vprofile-begin' '10.13.1.80 db01' '10.13.1.81 mc01' '10.13.1.82 rmq01' '10.13.1.83 app01' '10.13.1.84 web01' '10.13.1.85 nagios' '# vprofile-end' >> /etc/hosts
      echo '${base64gzip(file("${path.module}/scripts/ansible-prep.sh"))}' | base64 -d | gunzip > /root/ansible-prep.sh
      chmod +x /root/ansible-prep.sh
      systemd-run --unit=ansible-prep /bin/bash /root/ansible-prep.sh 'ansible' '${local.ansible_pubkey}'
    EOT
  }

  network {
    type               = "org"
    name               = "NDM"
    ip_allocation_mode = "MANUAL"
    ip                 = "10.13.1.85"
    is_primary         = true
    connected          = true
  }

  power_on = true
}
##############################################################################
