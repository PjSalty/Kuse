#!/usr/bin/env bash
#
# kubeconfig-switcher.sh
#
# Defines:
#   - kuse()        : switch KUBECONFIG to a chosen cluster folder
#   - kcs-list      : list available clusters
#   - kcs-current   : show current cluster
#   - kcs-help      : usage instructions
#
# Usage: source this file in your shell (e.g. ~/.bashrc or via the installer).

# 1) Load user overrides (if $KCS_CONFIG_FILE is set and exists)
if [ -n "${KCS_CONFIG_FILE:-}" ] && [ -f "${KCS_CONFIG_FILE}" ]; then
  # shellcheck source=/dev/null
  source "${KCS_CONFIG_FILE}"
fi

# 2) Default KUBECONFIG_ROOT if unset
: "${KUBECONFIG_ROOT:=$HOME/.kube/configs}"

# 3) Main function to switch kubeconfig
kuse() {
  local folder="$1"

  if [ -z "$folder" ]; then
    echo "Usage: kuse <cluster-folder-name|default>"
    echo "Available clusters under '$KUBECONFIG_ROOT':"
    if [ -d "$KUBECONFIG_ROOT" ]; then
      find "$KUBECONFIG_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" || \
        echo "  (none found)"
    else
      echo "  (no such directory: $KUBECONFIG_ROOT)"
    fi
    return 1
  fi

  if [ "$folder" = "default" ]; then
    unset KUBECONFIG
    unset CURRENT_KUBE_FOLDER
    echo "Switched to default kubeconfig"
    return 0
  fi

  local cluster_dir="$KUBECONFIG_ROOT/$folder"
  if [ ! -d "$cluster_dir" ]; then
    echo "Error: folder '$folder' not found under $KUBECONFIG_ROOT"
    return 1
  fi

  local config_path
  config_path=$(find "$cluster_dir" -maxdepth 1 \
                \( -name '*.kubeconfig' -o -name '*.yaml' -o -name '*.yml' \) \
                | head -n 1)

  if [ -n "$config_path" ] && [ -f "$config_path" ]; then
    export KUBECONFIG="$config_path"
    export CURRENT_KUBE_FOLDER="$folder"
    echo "Switched KUBECONFIG to: $config_path"

    # Persist choice for next shell (can override via KCS_STATE_FILE)
    local state_file="${KCS_STATE_FILE:-$HOME/.kcs_current}"
    echo "$folder" >"$state_file"
  else
    echo "Error: no .kubeconfig/.yaml found in $cluster_dir"
    return 1
  fi
}

# 4) Show current cluster + path
kcs-current() {
  if [ -n "${CURRENT_KUBE_FOLDER:-}" ]; then
    echo "Current cluster: $CURRENT_KUBE_FOLDER (KUBECONFIG=$KUBECONFIG)"
  else
    echo "No cluster selected (using default kubeconfig)."
  fi
}

# 5) List clusters
kcs-list() {
  if [ -d "$KUBECONFIG_ROOT" ]; then
    echo "Clusters under '$KUBECONFIG_ROOT':"
    find "$KUBECONFIG_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" \
      || echo "  (none found)"
  else
    echo "Error: KUBECONFIG_ROOT ($KUBECONFIG_ROOT) does not exist."
    return 1
  fi
}

# 6) Help text
kcs-help() {
  cat <<EOF
kuse <cluster-folder-name>
    Switch to the first .kubeconfig/.yaml file in that folder.

kuse default
    Unset KUBECONFIG (use ~/.kube/config or in-cluster defaults).

kcs-list
    List cluster folder names under KUBECONFIG_ROOT ($KUBECONFIG_ROOT).

kcs-current
    Show currently selected cluster and its KUBECONFIG path.

Environment overrides (in ~/.kcs.env or via shell):
  KUBECONFIG_ROOT   Root directory (default: ~/.kube/configs)
  KCS_CONFIG_FILE   Path to optional env file (default: none)
  KCS_STATE_FILE    Where to persist last choice (default: ~/.kcs_current)
EOF
}

# 7) On shell startup, auto-restore last cluster if no CURRENT_KUBE_FOLDER
if [ -z "${CURRENT_KUBE_FOLDER:-}" ]; then
  state_file="${KCS_STATE_FILE:-$HOME/.kcs_current}"
  if [ -f "$state_file" ]; then
    last_folder="$(<"$state_file")"
    if [ -d "$KUBECONFIG_ROOT/$last_folder" ]; then
      restored="$(find "$KUBECONFIG_ROOT/$last_folder" -maxdepth 1 \
                   \( -name '*.kubeconfig' -o -name '*.yaml' -o -name '*.yml' \) \
                   | head -n 1)"
      if [ -n "$restored" ] && [ -f "$restored" ]; then
        export KUBECONFIG="$restored"
        export CURRENT_KUBE_FOLDER="$last_folder"
      fi
    fi
  fi
fi
