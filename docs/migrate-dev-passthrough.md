# Moving CT 206 off raw `lxc.*` lines to `devN:`

**Why:** `pct set` rewrote `/etc/pve/lxc/206.conf` and dropped the hand-added
`lxc.mount.entry` / `lxc.cgroup2.devices.allow` lines twice (first `/dev/dri`, then
`/dev/net/tun`). `devN:` entries are real Proxmox config keys (PVE 8.1+), so `pct set`,
the web UI and Tofu all preserve them.

Do this by hand, once, on CT 206 first. Do CT 201 only after 206 has survived a week.

## 1. Find the gids inside the container

```bash
pct exec 206 -- getent group video render
# video:x:44:...   render:x:104:...   (yours may differ)
```

## 2. Checkpoint

```bash
make snapshot                      # from the repo, so the old conf is in git
pct snapshot 206 pre-devN          # on the host (ZFS, instant)
cp /etc/pve/lxc/206.conf /root/206.conf.bak
```

## 3. Edit

```bash
pct stop 206
nano /etc/pve/lxc/206.conf
```

Delete the raw lines for `/dev/dri`, `/dev/kfd` and `/dev/net/tun`, meaning the
`lxc.cgroup2.devices.allow: c 226:*`, `c 10:200` (and kfd's major) plus their
`lxc.mount.entry` partners. Add:

```ini
dev0: /dev/dri/card0,gid=44
dev1: /dev/dri/renderD128,gid=104
dev2: /dev/kfd,gid=104
dev3: /dev/net/tun
```

Check `ls /dev/dri` on the host first. Strix Halo may show up as `card1`, not `card0`.

## 4. Verify

```bash
pct start 206
pct exec 206 -- ls -l /dev/dri /dev/kfd /dev/net/tun
pct exec 206 -- tailscale status          # tun works
gpu-switch play                           # Sunshine grabs the display
```

Then stream from Moonlight and launch a game. Sound and a 60fps picture mean it worked.

Last, the actual point of this: `pct set 206 --memory <same value>`, then confirm the
`devN` lines are still in the conf.

## Rollback

```bash
pct stop 206 && pct rollback 206 pre-devN && pct start 206
```
