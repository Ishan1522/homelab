variable "node_name" {
  description = "Proxmox node name (Datacenter view in the web UI, or `hostname` on the host)"
  type        = string
  default     = "CHANGEME-node"
}

variable "datastore" {
  description = "Storage for container rootfs (the x4 NVMe ZFS pool)"
  type        = string
  default     = "local-zfs"
}

variable "template" {
  description = "LXC template, as listed by `pveam list local`"
  type        = string
  default     = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}
