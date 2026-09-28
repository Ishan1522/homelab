terraform {
  required_version = ">= 1.8"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox" # the maintained one; skip telmate/proxmox
      version = ">= 0.70.0, < 1.0.0"
    }
  }
}

# Credentials come from the environment, never from files in this repo:
#   PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_INSECURE
# `make plan` loads them from secrets/pve.sops.yaml via `sops exec-env`.
provider "proxmox" {}
