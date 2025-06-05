#!/usr/bin/env bash
#
# install.sh
# One‐step installer for kubeconfig‐switcher (“Kuse”), without requiring git
# and robustly handling any top‐level folder name in the tarball.
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

# 2) Locate the first `scripts/` directory inside $TMP_DIR (depth ≤ 3)
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

# 4) Copy the scripts into $SHAREDIR
echo "Copying scripts from $SCRIPT_DIR to $SHAREDIR..."
cp -r "$SCRIPT_DIR/"* "$SHAREDIR/"
chmod 0755 "$SHAREDIR"/*.sh
echo "  -> Done."
echo

# 5) Create the `kuse` wrapper in $BINDIR
echo "Creating wrapper script: $BINDIR/kuse"
cat <<'EOF' > "$BINDIR/kuse"
#!/usr/bin/env bash
#
# Simple wrapper for kubeconfig-switcher:
#   Sources the main script, then passes arguments to the function.

# If user did not set KCS_CONFIG_FILE, default to ~/.kcs.env
if [ -z "${KCS_CONFIG_FILE:-}" ]; then
  export KCS_CONFIG_FILE="$HOME/.kcs.env"
fi

# Compute where the shared scripts live (one level up from this wrapper)
KCS_SHAREDIR="$(dirname "$(readlink -f "$0")")/../share/kuse"
if [ -n "${KCS_SHAREDIR_OVERRIDE:-}" ]; then
  KCS_SHAREDIR="$KCS_SHAREDIR_OVERRIDE"
fi

# shellcheck source=/dev/null
source "$KCS_SHAREDIR/kubeconfig-switcher.sh"

# Delegate all arguments to the kuse() function
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

# 7) Remind about prompt helper
echo "Prompt helper script is at: $SHAREDIR/prompt-kuse.sh"
echo "To enable colored prompts, add this to your ~/.bashrc or ~/.zshrc:"
echo
echo "    source \"$SHAREDIR/prompt-kuse.sh\""
echo

# 8) Optionally append source lines to ~/.bashrc
read -r -p "Append 'source' lines to your ~/.bashrc now? [y/N] " answer
case "$answer" in
  [Yy]* )
    {
      echo
      echo "# >>> kubeconfig-switcher >>>"
      echo "export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
      echo "source \"$SHAREDIR/kubeconfig-switcher.sh\""
      echo "# 'kuse' wrapper is at $BINDIR/kuse"
      echo "# If you want the colored prompt, uncomment the next line:"
      echo "# source \"$SHAREDIR/prompt-kuse.sh\""
      echo "# <<< kubeconfig-switcher <<<"
    } >>"$HOME/.bashrc"
    echo "  -> Appended to ~/.bashrc."
    ;;
  * )
    echo "Skipping ~/.bashrc modification."
    echo "Remember to add to your shell startup (e.g. ~/.bashrc):"
    echo "  export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
    echo "  source \"$SHAREDIR/kubeconfig-switcher.sh\""
    ;;
esac

echo
echo "Installation complete! You can now run 'kuse' from the command line."
echo "Try:  kcs-list  or  kuse default"
echo

# 9) Clean up temporary extraction directory
rm -rf "$TMP_DIR"
