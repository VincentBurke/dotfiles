# setup.sh
#!/usr/bin/env bash
set -euo pipefail

# Detect whether the script is sourced (so we can return instead of exiting).
_is_sourced=0
(return 0 2>/dev/null) && _is_sourced=1

die() {
  echo "ERROR: $*" >&2
  if [[ $_is_sourced -eq 1 ]]; then
    return 1
  else
    exit 1
  fi
}

info() {
  echo "==> $*"
}

# macOS only
[[ "$(uname -s)" == "Darwin" ]] || die "This setup script is for macOS only."

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BREWFILE_TARGET="${BREWFILE_TARGET:-$HOME/.config/homebrew/Brewfile}"
CHEZMOI_CONFIG_DIR="$HOME/.config/chezmoi"
CHEZMOI_CONFIG_FILE="$CHEZMOI_CONFIG_DIR/chezmoi.toml"

[[ -d "$DOTFILES_DIR" ]] || die "Expected dotfiles repo at $DOTFILES_DIR (did you clone it to ~/.dotfiles?)."

# Ensure Xcode Command Line Tools exist (needed on fresh macOS installs)
if ! xcode-select -p >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Xcode Command Line Tools not found.

Run:
  xcode-select --install

Then re-run:
  cd ~/.dotfiles; source setup.sh
EOF
  if [[ $_is_sourced -eq 1 ]]; then return 1; else exit 1; fi
fi

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this shell session
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  # Fallback: attempt shellenv from whichever brew is found
  BREW_BIN="$(command -v brew || true)"
  [[ -n "$BREW_BIN" ]] || die "brew not found after installation."
  eval "$("$BREW_BIN" shellenv)"
fi

info "Updating Homebrew..."
brew update

# Install chezmoi if missing
if ! command -v chezmoi >/dev/null 2>&1; then
  info "Installing chezmoi..."
  brew install chezmoi
fi

# Write chezmoi config to remember this repo as sourceDir (optional but convenient)
mkdir -p "$CHEZMOI_CONFIG_DIR"
if [[ ! -f "$CHEZMOI_CONFIG_FILE" ]]; then
  info "Creating chezmoi config at $CHEZMOI_CONFIG_FILE"
  cat >"$CHEZMOI_CONFIG_FILE" <<EOF
sourceDir = "$DOTFILES_DIR"
EOF
else
  # If sourceDir isn't set yet, append it.
  if ! grep -qE '^\s*sourceDir\s*=' "$CHEZMOI_CONFIG_FILE"; then
    info "Updating chezmoi config to set sourceDir = $DOTFILES_DIR"
    printf '\nsourceDir = "%s"\n' "$DOTFILES_DIR" >>"$CHEZMOI_CONFIG_FILE"
  fi
fi

# Apply dotfiles
info "Applying dotfiles with chezmoi..."
chezmoi -S "$DOTFILES_DIR" apply

# Install Brewfile packages, if Brewfile exists (it should after apply)
if [[ -f "$BREWFILE_TARGET" ]]; then
  info "Installing Homebrew packages from Brewfile: $BREWFILE_TARGET"
  # brew bundle is built-in, but tapping is harmless if already present
  brew tap homebrew/bundle >/dev/null 2>&1 || true

  # Only run install if something is missing
  if ! brew bundle check --file="$BREWFILE_TARGET" >/dev/null 2>&1; then
    brew bundle install --file="$BREWFILE_TARGET"
  else
    info "Brewfile already satisfied."
  fi
else
  info "No Brewfile found at $BREWFILE_TARGET (skipping brew bundle)."
fi

info "Setup complete."
info "Recommended: restart your terminal (or run: exec zsh)"
