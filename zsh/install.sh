#!/usr/bin/env bash
set -euo pipefail

# OS detection
case "$(uname -s)" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
  *)      echo "unsupported OS"; exit 1 ;;
esac

# Distro detection (Linux only)
DISTRO=""
if [[ "$OS" == "linux" ]] && [[ -f /etc/os-release ]]; then
  source /etc/os-release
  DISTRO="$ID"
fi

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Package manager helpers
install_mac() {
  if ! command -v brew &>/dev/null; then
    echo "installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew install "$@"
}

install_linux() {
  case "$DISTRO" in
    arch|endeavouros|manjaro)
      if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "$@"
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$@"
      fi
      ;;
    ubuntu|debian|pop)
      sudo apt-get update -qq
      sudo apt-get install -y "$@"
      ;;
    fedora)
      sudo dnf install -y "$@"
      ;;
    *)
      echo "unsupported distro: $DISTRO"
      exit 1
      ;;
  esac
}

ensure() {
  local cmd="$1"
  shift
  if command -v "$cmd" &>/dev/null; then
    echo "$cmd: ok"
    return
  fi
  echo "$cmd: installing..."
  if [[ "$OS" == "mac" ]]; then
    install_mac "$@"
  else
    install_linux "$@"
  fi
}

# ==============================
# Install dependencies
# ==============================
echo "=== checking dependencies ==="

ensure zsh zsh
ensure fzf fzf
ensure stow stow
ensure go go
ensure fd fd
ensure eza eza
ensure zoxide zoxide
ensure yazi yazi
ensure lazygit lazygit
ensure nvim neovim

# starship
if command -v starship &>/dev/null; then
  echo "starship: ok"
else
  echo "starship: installing..."
  if [[ "$OS" == "mac" ]]; then
    install_mac starship
  elif [[ "$DISTRO" == "arch" || "$DISTRO" == "endeavouros" || "$DISTRO" == "manjaro" ]]; then
    install_linux starship
  else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
fi

# sheldon
if command -v sheldon &>/dev/null; then
  echo "sheldon: ok"
else
  echo "sheldon: installing..."
  if [[ "$OS" == "mac" ]]; then
    install_mac sheldon
  elif [[ "$DISTRO" == "arch" || "$DISTRO" == "endeavouros" || "$DISTRO" == "manjaro" ]]; then
    install_linux sheldon
  else
    if ! command -v cargo &>/dev/null; then
      echo "installing rust toolchain for sheldon..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      source "$HOME/.cargo/env"
    fi
    cargo install sheldon
  fi
fi

# fd has different binary names on Ubuntu/Debian
if [[ "$OS" == "linux" ]] && ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  echo "fd: creating symlink fdfind -> fd"
  sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# ==============================
# Symlink starship config from omarchy
# ==============================
echo ""
echo "=== linking starship config ==="
STARSHIP_SRC="$DOTFILES_DIR/omarchy/.config/starship.toml"
STARSHIP_DST="$HOME/.config/starship.toml"
if [[ -f "$STARSHIP_SRC" ]]; then
  mkdir -p "$HOME/.config"
  ln -sf "$STARSHIP_SRC" "$STARSHIP_DST"
  echo "starship.toml: linked"
else
  echo "starship.toml: omarchy config not found, skipping"
fi

# ==============================
# Stow symlinks
# ==============================
echo ""
echo "=== stowing zsh config ==="
cd "$DOTFILES_DIR"
stow -v --restow zsh

# ==============================
# Initialize sheldon plugins
# ==============================
echo ""
echo "=== initializing sheldon plugins ==="
sheldon lock

# ==============================
# Set zsh as default shell
# ==============================
if [[ "$SHELL" != */zsh ]]; then
  echo ""
  echo "=== setting zsh as default shell ==="
  chsh -s "$(command -v zsh)"
fi

echo ""
echo "=== done ==="
echo "restart your shell or run: exec zsh"
