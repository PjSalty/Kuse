#!/usr/bin/env bash
#
# completion-kuse.sh
# Bash completion for `kuse`.

_kuse_complete() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Always allow “default”
  opts="default"

  # If KUBECONFIG_ROOT is set (or defaulted), list subdirectories
  local root_dir="${KUBECONFIG_ROOT:-$HOME/.kube/configs}"
  if [ -d "$root_dir" ]; then
    opts+=" $(find "$root_dir" -maxdepth 1 -mindepth 1 -type d -printf "%f ")"
  fi

  COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
  return 0
}

complete -F _kuse_complete kuse
