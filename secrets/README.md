# secrets/

Only `*.sops.yaml` (encrypted) and `*.example` are committed. Everything else here
is gitignored.

Your age private key lives at `~/.config/sops/age/keys.txt` on each machine that
needs to decrypt (Mac, and the Surface's WSL). **Back that key up somewhere outside
this repo.** If you lose it, every secret in here is gone.
