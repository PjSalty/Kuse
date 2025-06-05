# Kuse

A small, self-contained Bash tool to switch between multiple kubeconfig files (organized in named subdirectories).

## Features

- **Easy context switching**  
  `kuse <cluster>` sets your `$KUBECONFIG` to the first `.kubeconfig` or `.yaml` file found in `$KUBECONFIG_ROOT/<cluster>`.  
  `kuse default` clears `$KUBECONFIG`, falling back to `~/.kube/config` (or in-cluster defaults).

- **Cluster inventory**  
  `kcs-list` shows all available cluster folder names under your root directory.  
  `kcs-current` displays which cluster (and exact file) is currently active.

- **Tab completion**  
  Installs a Bash-completion script so that typing `kuse <TAB>` will list “default” plus every folder name under `$KUBECONFIG_ROOT`.

- **Persistent state**  
  Remembers your last-used cluster in `~/.kcs_current` (or a custom path via `KCS_STATE_FILE`). New shells auto-restore that context.

- **Optional 256-color prompt**  
  If you source `prompt-kuse.sh`, your shell prompt will show the active cluster name in a uniquely hashed ANSI color (from the 216-color cube). No two clusters look the same.

- **One-step install**  
  A single `curl | sudo bash` (or `git clone && sudo make install`) drops all scripts into `/usr/local/share/kuse/` and places a `/usr/local/bin/kuse` wrapper in your `$PATH`, plus automatic Bash-completion integration.

- **Fully configurable**  
  Override your kubeconfig root (`KUBECONFIG_ROOT`) and state file location (`KCS_STATE_FILE`) via a simple `~/.kcs.env` file. Sensible defaults:  
  - `KUBECONFIG_ROOT="$HOME/.kube/configs"`  
  - `KCS_STATE_FILE="$HOME/.kcs_current"`

## Installation

### 1. One-step installer (curl | bash)

```bash
curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | sudo bash

