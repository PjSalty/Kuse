#!/usr/bin/env bash
#
# install.sh
# One‐step installer for kubeconfig‐switcher (“Kuse”).
# This version clones the GitHub repo into /tmp, then installs from there,
# so that `curl … | bash` works even if no local “scripts/” folder exists.
#
set -e

########################################
# CONFIGURABLES
########################################

# The GitHub repository URL:
REPO_URL="https://github.com/PjSalty/Kuse.git"
# Temporary location to clone into:
TMP_DIR="$(mktemp -d /tmp/Kuse-install.XXXXXX)"

# Default installation prefix (can be overridden via --prefix=)
PREFIX="/usr/local"
# Derived paths:
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

# Recalculate derived paths in case PREFIX changed
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

# 1) Clone the repo into TMP_DIR
echo "Cloning repository into temporary directory..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1 \
  || {
    echo "Error: failed to clone $REPO_URL"
    exit 1
  }
echo "  -> Cloned to $TMP_DIR"
echo

# 2) Create target directories
echo "Creating target directories..."
mkdir -p "$SHAREDIR" "$BINDIR"
echo "  -> $SHAREDIR"
echo "  -> $BINDIR"
echo

# 3) Copy scripts/ into SHAREDIR
echo "Copying scripts to $SHAREDIR..."
cp -r "$TMP_DIR/scripts/"* "$SHAREDIR/"
chmod 0755 "$SHAREDIR"/*.sh
echo "  -> Done."
echo

# 4) Create the `kuse` wrapper in BINDIR
echo "Creating wrapper script at $BINDIR/kuse..."
cat <<'EOF' > "$BINDIR/kuse"
#!/usr/bin/env bash
#
# Simple wrapper for kubeconfig-switcher:
#   sources the main script, then passes arguments to the function.

# If user did not explicitly set KCS_CONFIG_FILE, point it at ~/.kcs.env
if [ -z "${KCS_CONFIG_FILE:-}" ]; then
  export KCS_CONFIG_FILE="$HOME/.kcs.env"
fi

# Compute where the share directory is, relative to this wrapper
KCS_SHAREDIR="$(dirname "$(readlink -f "$0")")/../share/kuse"
# If user wants to override, they can set KCS_SHAREDIR_OVERRIDE
if [ -n "${KCS_SHAREDIR_OVERRIDE:-}" ]; then
  KCS_SHAREDIR="$KCS_SHAREDIR_OVERRIDE"
fi

# shellcheck source=/dev/null
source "$KCS_SHAREDIR/kubeconfig-switcher.sh"

# Dispatch to the kuse() function
kuse "$@"
EOF
chmod +x "$BINDIR/kuse"
echo "  -> Wrapper installed."
echo

# 5) Install bash completion (if available)
if [ -d "$COMPDIR" ]; then
  echo "Installing bash completion to $COMPDIR/kuse..."
  cp "$SHAREDIR/completion-kuse.sh" "$COMPDIR/kuse"
  chmod 0644 "$COMPDIR/kuse"
  echo "  -> Done."
else
  echo "Skipping bash completion: $COMPDIR not found."
fi
echo

# 6) Reminder about prompt helper
echo "Prompt helper script is located at: $SHAREDIR/prompt-kuse.sh"
echo "To enable colored prompts, add to your ~/.bashrc or ~/.zshrc:"
echo
echo "    source \"$SHAREDIR/prompt-kuse.sh\""
echo

# 7) Optionally append source lines to ~/.bashrc
read -r -p "Append 'source' lines to your ~/.bashrc now? [y/N] " answer
case "$answer" in
  [Yy]* )
    {
      echo
      echo "# >>> kubeconfig-switcher >>>"
      echo "export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
      echo "source \"$SHAREDIR/kubeconfig-switcher.sh\""
      echo "# The 'kuse' wrapper is at $BINDIR/kuse"
      echo "# If you want the colored prompt, uncomment next line:"
      echo "# source \"$SHAREDIR/prompt-kuse.sh\""
      echo "# <<< kubeconfig-switcher <<<"
    } >>"$HOME/.bashrc"
    echo "  -> Appended to ~/.bashrc."
    ;;
  * )
    echo "Skipping ~/.bashrc modification."
    echo "Remember to add the following to your shell startup file (`~/.bashrc`):"
    echo "  export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
    echo "  source \"$SHAREDIR/kubeconfig-switcher.sh\""
    ;;
esac

echo
echo "Installation complete! You can now use 'kuse' from the command line."
echo "Try:  kcs-list  or  kuse default"
echo

# 8) Clean up temporary clone
rm -rf "$TMP_DIR"
