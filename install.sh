#!/usr/bin/env bash
#
# install.sh
# One-step installer for kubeconfig-switcher
#
set -e

# Default installation prefix
PREFIX="/usr/local"
SHAREDIR="$PREFIX/share/kuse"
BINDIR="$PREFIX/bin"
COMPDIR="/etc/bash_completion.d"

### 1) Allow overrides via command-line ###
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

# Recompute dependent dirs if PREFIX changed
SHAREDIR="$PREFIX/share/kuse"
BINDIR="$PREFIX/bin"

echo "Installing kubeconfig-switcher to:"
echo "  Prefix:    $PREFIX"
echo "  Share dir: $SHAREDIR"
echo "  Bin dir:   $BINDIR"
echo

# 2) Create target directories
echo "Creating directories..."
sudo mkdir -p "$SHAREDIR" "$BINDIR"
echo "  -> $SHAREDIR"
echo "  -> $BINDIR"
echo

# 3) Copy scripts/ into $SHAREDIR
echo "Copying scripts to $SHAREDIR..."
sudo cp -r scripts/* "$SHAREDIR/"
sudo chmod 0755 "$SHAREDIR"/*.sh
echo "  -> Done."

# 4) Create the `kuse` wrapper in $BINDIR
cat <<'EOF' | sudo tee "$BINDIR/kuse" >/dev/null
#!/usr/bin/env bash
#
# Simple wrapper for kubeconfig-switcher:
#   sources the main script, then passes arguments to the function.

# Allow override of KCS_CONFIG_FILE if user set it
if [ -z "${KCS_CONFIG_FILE:-}" ]; then
  export KCS_CONFIG_FILE="$HOME/.kcs.env"
fi

# Determine share directory (adjust if custom PREFIX was used)
KCS_SHAREDIR="$(dirname "$(readlink -f "$0")")/../share/kuse"
# If user exported KCS_SHAREDIR_OVERRIDE, use that instead
if [ -n "${KCS_SHAREDIR_OVERRIDE:-}" ]; then
  KCS_SHAREDIR="$KCS_SHAREDIR_OVERRIDE"
fi

# shellcheck source=/dev/null
source "$KCS_SHAREDIR/kubeconfig-switcher.sh"

# Dispatch to the kuse() function
kuse "$@"
EOF

sudo chmod +x "$BINDIR/kuse"
echo "Created wrapper: $BINDIR/kuse"
echo

# 5) Install bash completion (if possible)
if [ -d "$COMPDIR" ]; then
  echo "Installing bash completion to $COMPDIR/kuse..."
  sudo cp "$SHAREDIR/completion-kuse.sh" "$COMPDIR/kuse"
  sudo chmod 0644 "$COMPDIR/kuse"
  echo "  -> Done."
else
  echo "Skipping bash completion: $COMPDIR not found."
fi
echo

# 6) Remind about prompt script
echo "Prompt helper located at: $SHAREDIR/prompt-kuse.sh"
echo "To enable colored prompt, add this line to your ~/.bashrc or ~/.zshrc:"
echo
echo "    source $SHAREDIR/prompt-kuse.sh"
echo

# 7) Optionally append sourcing lines to ~/.bashrc
read -r -p "Append 'source' lines to your ~/.bashrc now? [y/N] " answer
case "$answer" in
  [Yy]* )
    {
      echo
      echo "# >>> kubeconfig-switcher >>>"
      echo "export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
      echo "source \"$SHAREDIR/kubeconfig-switcher.sh\""
      echo "# kubeconfig-switcher wrapper is $BINDIR/kuse"
      echo "# If you want prompt colors, uncomment the next line:"
      echo "# source \"$SHAREDIR/prompt-kuse.sh\""
      echo "# <<< kubeconfig-switcher <<<"
    } >>"$HOME/.bashrc"
    echo "Appended to ~/.bashrc."
    ;;
  * )
    echo "Skipping ~/.bashrc modification."
    echo "Remember to add to your shell startup file:"
    echo "  export KCS_CONFIG_FILE=\"\$HOME/.kcs.env\""
    echo "  source \"$SHAREDIR/kubeconfig-switcher.sh\""
    ;;
esac

echo
echo "Installation complete! You can now use 'kuse' from the command line."
echo "Try:  kcs-list  or  kuse default"
echo
