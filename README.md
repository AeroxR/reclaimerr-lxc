# reclaimerr-lxc

Proxmox VE helper script that creates an LXC container running
[Reclaimerr](https://github.com/jessielw/Reclaimerr), in the style of the
[community-scripts](https://community-scripts.org/scripts) installers.

Unofficial and not affiliated with Reclaimerr or community-scripts.

## Install

Run in the Proxmox VE host shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AeroxR/reclaimerr-lxc/main/ct/reclaimerr.sh)"
```

Defaults: Debian 13, unprivileged, 2 cores, 2 GB RAM, 8 GB disk. Reclaimerr is
built from the latest upstream release and listens on port 8000.

## Update

Run `update` in the container's console.

## Layout inside the container

| Path | Contents |
| --- | --- |
| `/opt/reclaimerr` | Application (replaced on update) |
| `/var/lib/reclaimerr` | Database, logs, generated secrets |
| `/etc/reclaimerr/reclaimerr.env` | Configuration |

Service: `systemctl status reclaimerr`
