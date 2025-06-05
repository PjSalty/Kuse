# Kuse

A lightweight, self-contained shell tool to switch between multiple Kubernetes kubeconfig files organized in named subdirectories. After installation, simply drop each cluster’s kubeconfig into a folder under `~/.kube/configs/`, and use a single command to switch contexts effortlessly.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [System-wide Install (with sudo)](#system-wide-install-with-sudo)
  - [Home-directory-only Install (no sudo)](#home-directory-only-install-no-sudo)
- [Post-install Configuration](#post-install-configuration)
- [Usage](#usage)
  - [Example Folder Layout](#example-folder-layout)
  - [Built-in Commands](#built-in-commands)
- [Tab-Completion](#tab-completion)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Defaults & Configuration](#defaults--configuration)
- [Updating](#updating)
- [License](#license)
- [Contributing](#contributing)

---

## Features

- **Easy Context Switching**  
  - `kuse <cluster>` sets your `KUBECONFIG` to the first file matching `*.kubeconfig`, `*.yaml`, or `*.yml` inside `~/.kube/configs/<cluster>`.  
  - `kuse default` clears `KUBECONFIG`, falling back to the standard `~/.kube/config` (or in-cluster defaults).

- **Cluster Inventory**  
  - `kcs-list` lists all subdirectories under your kubeconfig root (default: `~/.kube/configs`).  
  - `kcs-current` displays which cluster (and the exact file path) is currently active.

- **Shell-native Tab Completion**  
  - Installs completion scripts for **Bash**, **Zsh**, and **Fish**. Typing `kuse <TAB>` will show `default` plus each folder name under your kubeconfig root.

- **Persistent State**  
  - Remembers your last-used cluster in `~/.kcs_current` so that new shells auto-restore that context.

- **Automatic Folder Creation**  
  - Installer automatically creates `~/.kube/configs` (or your custom root) if it doesn’t exist, so you can immediately drop your kubeconfig files there.

- **Colored Prompt by Default**  
  - A helper script appends the active cluster name to your shell prompt in a uniquely hashed 256-color hue—no two clusters look the same.

- **One-step Installer (No Git Required)**  
  - Install system-wide with:
    ```bash
    curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | sudo bash
    ```
  - Or install under your home directory (no sudo):
    ```bash
    curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | bash -s -- --prefix="$HOME/.local"
    ```

---

## Installation

### System-wide Install (with sudo)

```bash
curl -sSL https://raw.githubusercontent.com/PjSalty/Kuse/main/install.sh | sudo bash

