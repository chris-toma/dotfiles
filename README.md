# dotfiles

Cross-platform dotfiles for macOS, Ubuntu/Debian, Arch Linux, and Fedora.

## Structure

- `zsh/` — unified zsh config with OS detection (managed with [stow](https://www.gnu.org/software/stow/))
- `zsh/.config/sheldon/plugins.toml` — zsh plugin config ([sheldon](https://github.com/rossmacarthur/sheldon))
- `zsh/install.sh` — idempotent installer for all zsh dependencies
- `tmux/`, `tmuxp/` — tmux config and session layouts
- `ideavim/` — IdeaVim config
- `omarchy/` — Arch Linux / Omarchy desktop configs (Hyprland, Alacritty, Waybar, starship)
- `ghostty/` — Ghostty terminal config

## Quick Start

```bash
git clone git@github.com:chris-toma/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./zsh/install.sh
```

The install script will:
- Detect your OS and distro
- Install all dependencies using the correct package manager (brew/yay/pacman/apt/dnf)
- Symlink zsh configs via stow (`.zshrc`, `.aliasesrc`, `.config/sheldon/`)
- Symlink `starship.toml` from the omarchy package
- Initialize sheldon plugins
- Set zsh as default shell

### Dependencies installed

zsh, fzf, stow, go, fd, eza, zoxide, yazi, lazygit, neovim, starship, sheldon

### Update zsh plugins

```bash
sheldon lock --update
```

## tmux

```bash
cd ~/.dotfiles
stow tmux tmuxp
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux:
```
Ctrl+s I       # install plugins
Ctrl+r         # reload environment
Ctrl+s U       # update plugins
```

## IdeaVim

```bash
cd ~/.dotfiles
stow ideavim
```

## Ghostty

```bash
cd ~/.dotfiles
stow ghostty
```
