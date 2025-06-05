#!/usr/bin/env bash
#
# install.sh
# One‐step, non-interactive installer for kubeconfig‐switcher (“Kuse”), no further manual edits.
#
set -e

########################################
# CONFIGURABLES
########################################

# GitHub tarball URL for the main branch:
TARBALL_URL="https://codeload.github.com/PjSalty/Kuse/tar.gz/refs/heads/main"

# Temporary directory to download and extract into:
TMP_DIR="$(mktemp -d /tmp/Kuse-install.XXXXXX)"

# Default installation prefix (override via --prefix=/some/path)
PREFIX="/usr/local"
SHAREDIR="$PREFIX/share/kuse"
BINDIR="$PREFIX/bin"
COMPDIR="/etc/bash_completion.d"

########################################
# PARSE ARGS
########################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix=*)
      PREFIX="${1#--prefix=}"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--prefix=/some/path]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--prefix=/some/path]"
      exit 1
      ;;
  esac
done

# Recompute derived paths if PREFIX changed
SHAREDIR="$PREFIX/share/kuse"
BINDIR="$PREFIX/bin"

########################################
# BEGIN INSTALL
########################################
echo "Installing kubeconfig-switcher to:"
echo "  Prefix:    $PREFIX"
echo "  Share dir: $SHAREDIR"
echo "  Bin dir:   $BINDIR"
echo

# 1) Download & extract tarball into TMP_DIR
echo "Downloading and extracting repository tarball..."
curl -sSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR"
echo "  -> Extracted under $TMP_DIR"
echo

# 2) Locate the first `scripts/` directory inside TMP_DIR (depth ≤ 3)
echo "Locating 'scripts/' directory within the extracted tarball..."
SCRIPT_DIR="$(find "$TMP_DIR" -maxdepth 3 -type d -name scripts | head -n1)"
if [ -z "$SCRIPT_DIR" ]; then
  echo "Error: could not locate a 'scripts/' directory in $TMP_DIR"
  rm -rf "$TMP_DIR"
  exit 1
fi
echo "  -> Found scripts at: $SCRIPT_DIR"
echo

# 3) Create target directories
echo "Creating target directories..."
mkdir -p "$SHAREDIR" "$BINDIR"
echo "  -> $SHAREDIR"
echo "  -> $BINDIR"
echo

# 4) Copy the scripts into SHAREDIR
echo "Copying scripts from $SCRIPT_DIR to $SHAREDIR..."
cp -r "$SCRIPT_DIR/"* "$SHAREDIR/"
chmod 0755 "$SHAREDIR"/*.sh
echo "  -> Done."
echo

# 5) Create the `kuse` wrapper in BINDIR
echo "Creating wrapper script: $BINDIR/kuse"
cat <<'EOF' > "$BINDIR/kuse"
#!/usr/bin/env bash
#
# Simple wrapper for kubeconfig-switcher:
#   Sources the main script, then passes arguments to the function.

# Ensure KCS_CONFIG_FILE is set (defaults to ~/.kcs.env)
if [ -z "${KCS_CONFIG_FILE:-}" ]; then
  export KCS_CONFIG_FILE="$HOME/.kcs.env"
fi

# Determine share directory relative to this wrapper
KCS_SHAREDIR="$(dirname "$(readlink -f "$0")")/../share/kuse"
if [ -n "${KCS_SHAREDIR_OVERRIDE:-}" ]; then
  KCS_SHAREDIR="$KCS_SHAREDIR_OVERRIDE"
fi

# shellcheck source=/dev/null
source "$KCS_SHAREDIR/kubeconfig-switcher.sh"

# Delegate all args to the kuse() function
kuse "$@"
EOF
chmod +x "$BINDIR/kuse"
echo "  -> Wrapper installed."
echo

# 6) Install bash completion (if available)
if [ -d "$COMPDIR" ]; then
  echo "Installing bash completion: $COMPDIR/kuse"
  cp "$SHAREDIR/completion-kuse.sh" "$COMPDIR/kuse"
  chmod 0644 "$COMPDIR/kuse"
  echo "  -> Completed."
else
  echo "Skipping bash completion (directory $COMPDIR not found)."
fi
echo

# 7) Ensure ~/.kcs.env exists (create if missing)
if [ ! -f "$HOME/.kcs.env" ]; then
  echo "# ~/.kcs.env: override defaults for kubeconfig-switcher" > "$HOME/.kcs.env"
  echo "# export KUBECONFIG_ROOT=\"\$HOME/.kube/configs\"" >> "$HOME/.kcs.env"
  echo "# export KCS_STATE_FILE=\"\$HOME/.kcs_current\"" >> "$HOME/.kcs.env"
  chmod 0644 "$HOME/.kcs.env"
  echo "Created default ~/.kcs.env"
fi
echo

# 8) Append source lines to ~/.bashrc if not already present
BASHRC="$HOME/.bashrc"
grep -qxF "# >>> kubeconfig-switcher >>>" "$BASHRC" 2>/dev/null || {
  {
    echo
    echo "# >>> kubeconfig-switcher >>>"
    echo "export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
    echo "source \"$SHAREDIR/kubeconfig-switcher.sh\""
    echo "# 'kuse' wrapper is at $BINDIR/kuse"
    echo "# If you want the colored prompt, uncomment next line:"
    echo "# source \"$SHAREDIR/prompt-kuse.sh\""
    echo "# <<< kubeconfig-switcher <<<"
  } >> "$BASHRC"
  echo "Appended kubeconfig-switcher lines to $BASHRC"
}
echo

# 9) Clean up temporary extraction directory
rm -rf "$TMP_DIR"

echo
echo "Installation complete! Start a new shell or run 'source ~/.bashrc' to use 'kuse'."
echo "Examples:"
echo "  kcs-list"
echo "  kuse <cluster-folder-name>"
echo "  kcs-current"
echo "  kuse default"
echo

