# dotfiles

## Structure

- `tmux/`, `tmuxp/`, `zsh/`, `ideavim/` — macOS configs (managed with [stow](https://www.gnu.org/software/stow/))
- `zsh/.config/sheldon/plugins.toml` — zsh plugin config ([sheldon](https://github.com/rossmacarthur/sheldon))
- `linux/` — Linux-specific overrides, same directory layout

## macOS Setup

### Symlink dotfiles
```bash
cd ~/.dotfiles
stow tmux tmuxp zsh ideavim
```

### tmux
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
```bash
Ctrl + s + I # Install plugins
Ctrl + r # Reload tmux environment
Ctrl + s + U # Update plugins
```

### zsh
Plugins are managed by [sheldon](https://github.com/rossmacarthur/sheldon). Config lives in `zsh/.config/sheldon/plugins.toml` and is symlinked via stow.
```bash
brew install sheldon
sheldon lock
```
To update plugins:
```bash
sheldon lock --update
```

---

## Linux Setup

Uses files from `linux/` which override the macOS defaults.

### Key differences from macOS
- Paths use `/home/<user>/` instead of `/Users/<user>/`
- Docker started via `sudo systemctl start docker` (not `open -a Docker`)
- `listen` alias uses `ss -tlnp` instead of `lsof`
- No macOS firewall commands
- No Homebrew paths; uses system package manager
- tmux windows use `@managed` option so tmuxp-managed windows keep their names

### Symlink dotfiles
```bash
# tmux (shared config + linux window-name.zsh)
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
mkdir -p ~/.tmux
ln -sf ~/dotfiles/tmux/.tmux/plugins ~/.tmux/plugins
ln -sf ~/dotfiles/linux/tmux/.tmux/window-name.zsh ~/.tmux/window-name.zsh

# tmuxp
ln -sf ~/dotfiles/linux/tmuxp/.tmuxp ~/.tmuxp

# zsh
ln -sf ~/dotfiles/linux/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/linux/zsh/.aliasesrc ~/.aliasesrc

# ideavim (shared)
ln -sf ~/dotfiles/ideavim/.ideavimrc ~/.ideavimrc
```

### tmux
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
```bash
Ctrl + s + I # Install plugins
Ctrl + r # Reload tmux environment
Ctrl + s + U # Update plugins
```

### zsh
Plugins are managed by [sheldon](https://github.com/rossmacarthur/sheldon).
```bash
# install sheldon (use your distro's package manager or cargo)
cargo install sheldon
sheldon lock
```
To update plugins:
```bash
sheldon lock --update
```

### Dependencies (for c8-start)
```bash
sudo apt install docker.io
pip install tmuxp
```