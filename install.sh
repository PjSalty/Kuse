#!/usr/bin/env bash
#
# install.sh
# One‐step installer for kubeconfig‐switcher (“Kuse”), without requiring git.
# It fetches the main branch as a tarball, extracts scripts/, then installs.
#
set -e

########################################
# CONFIGURABLES
########################################

# The GitHub “archive” URL for the main branch tarball:
TARBALL_URL="https://codeload.github.com/PjSalty/Kuse/tar.gz/refs/heads/main"

# Temporary directory to download and extract the tarball:
TMP_DIR="$(mktemp -d /tmp/Kuse-install.XXXXXX)"

# Default installation prefix (override with --prefix=/somewhere if desired)
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

# 1) Download and extract only the 'scripts/' directory from the tarball
echo "Downloading and extracting repository tarball..."
curl -sSL "$TARBALL_URL" | tar -xz -C "$TMP_DIR"
# The tarball creates a top-level folder named "Kuse-main/"
# We want to extract scripts/ from that folder
REPO_ROOT="$TMP_DIR/Kuse-main"

if [ ! -d "$REPO_ROOT/scripts" ]; then
  echo "Error: failed to find scripts/ in the tarball"
  rm -rf "$TMP_DIR"
  exit 1
fi
echo "  -> Extracted to $REPO_ROOT"
echo

# 2) Create target directories
echo "Creating target directories..."
mkdir -p "$SHAREDIR" "$BINDIR"
echo "  -> $SHAREDIR"
echo "  -> $BINDIR"
echo

# 3) Copy scripts/ into SHAREDIR
echo "Copying scripts to $SHAREDIR..."
cp -r "$REPO_ROOT/scripts/"* "$SHAREDIR/"
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
    echo "Remember to add the following to your shell startup file (e.g. ~/.bashrc):"
    echo "  export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
    echo "  source \"$SHAREDIR/kubeconfig-switcher.sh\""
    ;;
esac

echo
echo "Installation complete! You can now use 'kuse' from the command line."
echo "Try:  kcs-list  or  kuse default"
echo

# 8) Clean up temporary files
rm -rf "$TMP_DIR"
