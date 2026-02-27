# Changelog

All notable changes to this dotfiles repository are documented in this file.

## 2026-02-27

### Unified zsh configuration across macOS, Linux, and Arch

- **Removed** `linux/zsh/` directory — no longer maintaining separate Linux zsh configs
- **Unified** `zsh/.zshrc` with OS detection to work on macOS, Ubuntu/Debian, Arch, and Fedora
  - Homebrew setup conditionally runs on macOS only
  - SSH agent auto-management conditionally runs on Linux only
- **Unified** `zsh/.aliasesrc` with OS-conditional aliases
  - `listen` uses `lsof` on macOS, `ss` on Linux
  - `mollie_env` only defined on macOS
  - Fixed hardcoded `/Users/christoma` paths to use `$HOME`
- **Standardized** on sheldon + starship across all platforms (replaced oh-my-zsh + powerlevel10k on Linux)

### Added `zsh/install.sh` — idempotent cross-platform installer

- Detects OS and distro, uses the correct package manager (brew/yay/pacman/apt/dnf)
- Checks and installs all dependencies: zsh, fzf, stow, go, fd, eza, zoxide, yazi, lazygit, neovim, starship, sheldon
- Falls back to cargo for sheldon and curl installer for starship on distros without native packages
- Handles Ubuntu's `fdfind` → `fd` binary name difference
- Symlinks `starship.toml` from the omarchy stow package
- Stows zsh config symlinks via `stow --restow`
- Initializes sheldon plugins via `sheldon lock`
- Sets zsh as default shell if it isn't already
- Added `zsh/.stow-local-ignore` to prevent `install.sh` from being symlinked to `$HOME`
