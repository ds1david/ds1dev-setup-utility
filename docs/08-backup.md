# 08 — Backup e restauração

A backup strategy must address the three native workspace roots separately:
- Windows: C:\workspace; preserve local/bin, local/env, local/config, manifests and logs as appropriate.
- Ubuntu: /workspace ext4 and WSL export; preserve dotfiles/home if relevant.
- MSYS2: /workspace inside the MSYS2 installation; preserve UCRT64 package manifest and shell configs.

Use encrypted backups for secrets. Do not synchronize active Docker volumes, databases, sensitive company repositories or build caches. WSL export requires identifying distro via wsl -l -v. Verify actual restoration on a separate machine or isolated environment. Logs must never store credentials in plaintext.