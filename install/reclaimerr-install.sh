#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AeroxR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jessielw.github.io/Reclaimerr/ | Github: https://github.com/jessielw/Reclaimerr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "reclaimerr" "jessielw/Reclaimerr" "tarball" "latest" "/opt/reclaimerr"

msg_info "Building Frontend"
cd /opt/reclaimerr/frontend
$STD npm install
VITE_APP_CHANNEL=release $STD npm run build
rm -rf /opt/reclaimerr/frontend/node_modules
msg_ok "Built Frontend"

msg_info "Installing Backend"
cd /opt/reclaimerr
if [[ -f uv.lock ]]; then
  $STD uv sync --frozen --no-dev --no-install-project --python 3.13
else
  $STD uv sync --no-dev --no-install-project --python 3.13
fi
msg_ok "Installed Backend"

msg_info "Configuring Reclaimerr"
mkdir -p /etc/reclaimerr /var/lib/reclaimerr/{database,logs,static/avatars,static/collection-posters}
chmod 750 /var/lib/reclaimerr
# The static, avatar and poster directories are separate settings upstream and
# do not follow DATA_DIR, so each one is pinned here. Keeping data and config
# outside /opt/reclaimerr lets updates replace the application directory.
cat <<EOF >/etc/reclaimerr/reclaimerr.env
DATA_DIR=/var/lib/reclaimerr
STATIC_DIR=/var/lib/reclaimerr/static
AVATARS_DIR=/var/lib/reclaimerr/static/avatars
COLLECTION_POSTERS_DIR=/var/lib/reclaimerr/static/collection-posters
FRONTEND_DIST=/opt/reclaimerr/frontend/dist
API_HOST=0.0.0.0
API_PORT=8000
PROXY_TRUSTED_HOSTS=127.0.0.1,::1
RECLAIMERR_COMMAND_WORKERS=2
LOG_LEVEL=INFO
EOF
chmod 640 /etc/reclaimerr/reclaimerr.env
msg_ok "Configured Reclaimerr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/reclaimerr.service
[Unit]
Description=Reclaimerr
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/reclaimerr
EnvironmentFile=/etc/reclaimerr/reclaimerr.env
Environment=PYTHONPATH=/opt/reclaimerr
Environment=PYTHONUNBUFFERED=1
Environment=PYTHONDONTWRITEBYTECODE=1
UMask=0002
ExecStart=/opt/reclaimerr/.venv/bin/granian --interface asgi --workers 1 --host \${API_HOST} --port \${API_PORT} backend.api.main:app
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
SyslogIdentifier=reclaimerr

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now reclaimerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
