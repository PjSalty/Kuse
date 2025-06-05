# Kuse

A lightweight shell tool to switch between multiple kubeconfig files organized in named subdirectories. After installation, simply drop each cluster’s kubeconfig into a folder under `~/.kube/configs/`, and use a single command to switch contexts.

---

## Features

- **Easy context switching**  
  `kuse <cluster>` sets your `KUBECONFIG` to the first `*.kubeconfig`, `*.yaml`, or `*.yml` file found in `~/.kube/configs/<cluster>`.  
  `kuse default` clears `KUBECONFIG`, falling back to `~/.kube/config`.

- **Cluster inventory**  
  - `kcs-list` shows all subdirectories under your kubeconfig root (default `~/.kube/configs`).  
  - `kcs-current` displays which cluster (and exact file) is currently active.

- **Shell-native tab completion**  
  Installs completion scripts for **Bash**, **Zsh**, and **Fish**. Typing `kuse <TAB>` will list `default` plus each folder name under your kubeconfig root.

- **Persistent state**  
  Remembers your last-used cluster in `~/.kcs_current`. New shells automatically restore that context.

- **Automatic folder creation**  
  The installer creates `~/.kube/configs` if it doesn’t already exist, so you can immediately drop kubeconfig files there.

- **Colored prompt by default**  
  A helper script injects the active cluster name into your shell prompt in a unique 256-color hue.

- **One-step installer (no Git required)**  
  ```bash
  curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | sudo bash
  # Or, to install under your home directory (no sudo):
  curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | bash -s -- --prefix="$HOME/.local"

