#!/usr/bin/env bash
# Where this script and install/reclaimerr-install.sh are hosted. Change this to
# your own repository; it is also where the in-container "update" command looks.
_CS_DEFAULT_URL="${_CS_DEFAULT_URL:-https://raw.githubusercontent.com/AeroxR/reclaimerr-lxc/main}"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: AeroxR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jessielw.github.io/Reclaimerr/ | Github: https://github.com/jessielw/Reclaimerr

APP="Reclaimerr"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/reclaimerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "reclaimerr" "jessielw/Reclaimerr"; then
    msg_info "Stopping Service"
    systemctl stop reclaimerr
    msg_ok "Stopped Service"

    # Data and config live outside /opt/reclaimerr (/var/lib/reclaimerr and
    # /etc/reclaimerr), so wiping the application directory is safe.
    NODE_VERSION="24" setup_nodejs
    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "reclaimerr" "jessielw/Reclaimerr" "tarball" "latest" "/opt/reclaimerr"

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

    msg_info "Starting Service"
    systemctl start reclaimerr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
