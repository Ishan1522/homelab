# homelab - TEMPLATE for now. Also how did claude even get commit credit bruh

Infrastructure-as-code for the MS-S1 Max Proxmox box (+ the MacBook data node).

| Layer | Tool | Owns |
|---|---|---|
| Record of what's live | `scripts/snapshot.sh` | Raw copies of `/etc/pve/*`, host files, container files → `snapshots/` |
| Config on host + inside containers | Ansible (`ansible/`) | fstab/NFS, gpu-switch, Sunshine/Pulse units, baseline packages |
| Which containers exist | OpenTofu (`tofu/`) | New CTs with pinned MACs; old CTs imported one at a time |
| Secrets | sops + age (`secrets/`) | Proxmox API token, auth keys |

## The rule for the first run: adopt, don't rebuild

The goal of the first `make check` is **zero changes**. Zero changes means the repo
describes reality exactly. Only after that do you start changing things *through* the repo.

```
repo  ──(make check)──▶  "would change 0 things"   ✅ repo == reality
repo  ──(make check)──▶  "would change 3 things"   ❌ read the diff, fix the REPO, not the server
```

## First-run checklist

1. **Tools** (on the Mac, or WSL on the Surface; Ansible doesn't run natively on Windows):
   ```bash
   brew install ansible opentofu sops age
   make deps
   ```
2. **Fill in placeholders**: `grep -rn CHANGEME .` and replace every hit. The containers
   need sshd + your key over Tailscale (CT 201 has it; check CT 206).
3. **Snapshot live state**: `git init`, set `PVE_HOST` in `scripts/snapshot.sh`, then
   `make snapshot`. This fills `snapshots/` and commits it.
4. **Swap scaffold placeholders for your real files.** Any file containing
   `SCAFFOLD-PLACEHOLDER` is a reference version written from notes, and the playbook
   **refuses to deploy it** until you replace it:
   ```bash
   grep -rln SCAFFOLD-PLACEHOLDER ansible/
   cp snapshots/host/gpu-switch            ansible/roles/pve_host/files/gpu-switch
   mkdir -p ansible/roles/sunshine_stream/files/{game-dev,game-playing}
   cp snapshots/ct206/pulse-start.sh        ansible/roles/sunshine_stream/files/game-playing/
   cp snapshots/ct206/xfce-display.service  ansible/roles/sunshine_stream/files/game-playing/
   cp snapshots/ct206/sunshine.service      ansible/roles/sunshine_stream/files/game-playing/
   # ...same for ct201 → files/game-dev/
   ```
   Per-host files in `files/<inventory_hostname>/` override the shared ones in `files/`.
5. **Dry run**: `make check`. Iterate until it reports no changes.
6. **Secrets**: `age-keygen -o ~/.config/sops/age/keys.txt`, put the public key in
   `.sops.yaml`, then `sops secrets/pve.sops.yaml` (template in `secrets/*.example`).
7. **Tofu**: `make plan`. With the defaults it should plan **nothing**. See `tofu/README.md`.

## Day-to-day

```bash
make snapshot   # before and after any hand-edit on the box, so drift shows up in git
make check      # what would Ansible change?
make apply      # do it
make plan       # what would Tofu change? (read it, especially "must be replaced")
```

## Guardrails baked in

- Placeholder files can't be deployed (assert in each role).
- Ansible **checks** the CT 203 vault bind-mount but never runs `pct set` on it.
  `pct set` already ate raw lines on CT 206 twice, so Proxmox container config stays
  hands-off until Tofu owns that container.
- The Sunshine role never enables or starts the display units. `gpu-switch` decides
  which container holds the GPU.
- Tofu's container map starts empty, so the first `make plan` is a no-op. Every managed
  container gets `prevent_destroy`.
- `docs/migrate-dev-passthrough.md` covers moving CT 206 off raw `lxc.*` lines. Do it by hand, once.

## Manual steps that stay manual

- MSU `dhcpproxy` MAC registration. Pinned MACs in Tofu make this a one-time step per container.
- Sunshine web-UI creds (`sunshine --creds`). Store them in sops so you stop resetting them.
