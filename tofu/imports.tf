# Adopting an existing container, one at a time, least precious first (CT 205).
#
# 1. Add a matching entry to local.containers in containers.tf, with the REAL
#    vm_id, MAC, cores, memory and disk from snapshots/pve/lxc/205.conf.
# 2. Uncomment the block below and run `make plan`.
# 3. Keep editing the map until the plan says "1 to import, 0 to add, 0 to change,
#    0 to destroy". If it ever says "must be replaced", STOP. That rebuilds the container.
# 4. `make tofu-apply`, then delete this block (the import is recorded in state).
#
# import {
#   to = proxmox_virtual_environment_container.ct["nginx-proxy-manager"]
#   id = "CHANGEME-node/205"
# }
#
# Leave CT 201 and CT 206 for last. Their GPU passthrough lines are the fragile part.
