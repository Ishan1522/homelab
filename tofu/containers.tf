# One map entry = one container. The map starts EMPTY on purpose: `make plan`
# should say "No changes" until you add something.
#
# Why pin the MAC: MSU's dhcpproxy portal registers per MAC. A pinned MAC means a
# destroyed-and-rebuilt container comes back already registered. BC:24:11 is
# Proxmox's own prefix; pick the last three bytes yourself and keep them unique.
locals {
  containers = {
    # "scratch" = {
    #   vm_id  = 207
    #   mac    = "BC:24:11:00:02:07"   # register this on dhcpproxy BEFORE apply
    #   cores  = 2
    #   memory = 2048
    #   disk   = 16
    #   docker = true                  # turns on nesting
    # }
  }
}

resource "proxmox_virtual_environment_container" "ct" {
  for_each = local.containers

  node_name    = var.node_name
  vm_id        = each.value.vm_id
  unprivileged = true
  started      = true
  description  = "managed by tofu (homelab repo)"
  tags         = ["tofu"]

  initialization {
    hostname = each.key
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = each.value.mac
  }

  operating_system {
    template_file_id = var.template
    type             = "debian"
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.datastore
    size         = each.value.disk
  }

  features {
    nesting = lookup(each.value, "docker", false)
  }

  lifecycle {
    # To really delete one: remove this line in the same commit, apply, put it back.
    prevent_destroy = true
  }
}
