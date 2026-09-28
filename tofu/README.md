# tofu/

Owns **which containers exist** and their shape (CPU, RAM, disk, NIC, MAC).
Ansible owns what runs inside them.

## Setup

1. Make a Proxmox API token: Datacenter → Permissions → API Tokens.
   Use a token on `root@pam` with privilege separation **off**.
   Heads-up: Proxmox only lets a real `root@pam` *login* change container `features`
   (like `nesting` for Docker) and host bind mounts. If an apply fails with a permission
   error on those, swap the token for `PROXMOX_VE_USERNAME` / `PROXMOX_VE_PASSWORD`
   (commented out in the example secrets file).
2. Put it in `secrets/pve.sops.yaml` (see `secrets/pve.sops.yaml.example`).
3. Set `node_name` in `variables.tf`.
4. `make plan` → should print **No changes**.

## State

State is local (`terraform.tfstate`, gitignored) and holds your container specs.
Back it up with the rest of the Mac's rsync backups. Moving it to a remote backend
(e.g. S3-compatible MinIO in a container) is a later upgrade, not a day-one thing.

## Reading a plan

| Plan says | Meaning |
|---|---|
| `No changes` | repo == reality |
| `~ update in-place` | safe-ish, read the diff |
| `-/+ must be replaced` | **destroys the container**. Don't apply. Fix the map to match reality |
| `Instance cannot be destroyed` | `prevent_destroy` did its job |
