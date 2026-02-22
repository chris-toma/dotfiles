# AI Agent Plan: Zsh + Oh My Zsh + Powerlevel10k Setup

You are setting up a Linux (Ubuntu/Debian) machine with zsh, Oh My Zsh, Powerlevel10k, and configuring terminal emulators. Follow these steps **in order**. Each step has preconditions, exact commands, and a verification check. Do not skip verifications.

**Target OS:** Ubuntu/Debian (tested on Ubuntu 24.04)
**Target user:** The current logged-in user (`$USER`)

---

## Step 1: Make sudo passwordless

**Goal:** Allow `$USER` to run `sudo` without a password prompt.

**Commands:**
```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER-nopasswd
sudo chmod 440 /etc/sudoers.d/$USER-nopasswd
```

**Verify:** Run `sudo visudo -c` — output must say `parsed OK` for all files. Then run `sudo echo "ok"` — it must succeed without prompting for a password.

**Rollback:** `sudo rm /etc/sudoers.d/$USER-nopasswd`

---

## Step 2: Install zsh

**Goal:** Install the zsh shell via the system package manager.

**Commands:**
```bash
sudo apt update && sudo apt install -y zsh
```

**Verify:** Run `which zsh` — must return `/usr/bin/zsh`. Run `zsh --version` — must show version output.

---

## Step 3: Install Oh My Zsh

**Goal:** Install the Oh My Zsh framework into `~/.oh-my-zsh`. This also creates `~/.zshrc`.

**Precondition:** zsh must be installed (Step 2).

**Commands:**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

**Important:** The `--unattended` flag prevents the installer from switching the shell or requiring interactive input.

**Verify:** Directory `~/.oh-my-zsh` must exist. File `~/.zshrc` must exist and contain `ZSH_THEME`.

---

## Step 4: Install a Nerd Font

**Goal:** Powerlevel10k requires a Nerd Font for icons/glyphs. Install CaskaydiaMono Nerd Font.

**Check first:** Run `fc-list | grep -i "CaskaydiaMono Nerd"`. If output is non-empty, skip this step.

**Commands (if font is missing):**
```bash
mkdir -p ~/.local/share/fonts
curl -fLO --output-dir ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
unzip ~/.local/share/fonts/CascadiaCode.zip -d ~/.local/share/fonts/CascadiaCode
rm ~/.local/share/fonts/CascadiaCode.zip
fc-cache -fv
```

**Verify:** Run `fc-list | grep -i "CaskaydiaMono Nerd"` — must return at least one line.

---

## Step 5: Install Powerlevel10k theme

**Goal:** Clone the Powerlevel10k theme into Oh My Zsh's custom themes directory and activate it.

**Precondition:** Oh My Zsh must be installed (Step 3).

**Commands:**
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Then edit `~/.zshrc`:** Find the line `ZSH_THEME="robbyrussell"` (or whatever value it has) and replace it with:
```
ZSH_THEME="powerlevel10k/powerlevel10k"
```

**Also append to the end of `~/.zshrc`:**
```bash
# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

**Verify:** `grep 'ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc` must match. Directory `~/.oh-my-zsh/custom/themes/powerlevel10k` must exist.

**Note:** The Powerlevel10k configuration wizard (`p10k configure`) runs interactively on first zsh launch. You cannot run it non-interactively. Inform the user they need to run it manually after setup.

### 5b: Install zsh plugins

Clone these four plugins into Oh My Zsh's custom plugins directory:

```bash
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/jeffreytse/zsh-vi-mode.git "$ZSH_CUSTOM/plugins/zsh-vi-mode"
git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
```

**Then edit `~/.zshrc`:** Find the `plugins=(...)` line and replace it with:
```bash
plugins=(git history zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode)
```

**Also add above the `source $ZSH/oh-my-zsh.sh` line (zsh-completions needs special loading):**
```bash
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
```

**Verify:** All four directories must exist:
```bash
ls -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-vi-mode ~/.oh-my-zsh/custom/plugins/zsh-completions
```

---

## Step 6: Set zsh as the default shell

**Goal:** Make zsh the login shell for `$USER`.

**Commands:**
```bash
sudo chsh -s $(which zsh) $USER
```

**Verify:** Run `grep "^$USER:" /etc/passwd` — the last field must be `/usr/bin/zsh`.

**Note:** The change takes effect on next login/reboot, not in the current session.

---

## Step 7: Port bash config to zsh and apply dotfiles

**Goal:** Carry over useful aliases, PATH, environment variables, and tool initializations from the existing bash setup into `~/.zshrc`. Also deploy zsh, tmux, and tmuxp configs from the dotfiles repo.

**Precondition:** Read the existing `~/.bashrc` (and any files it sources) to discover what needs porting. The dotfiles repo must be cloned (Step 16).

### 7a: Add settings to `~/.zshrc`

Add these lines near the top of `~/.zshrc`, after the `export ZSH=` line:

```bash
export DISABLE_AUTO_TITLE='true'
set -o vi
```

Add fzf key bindings before the `ZSH_THEME` line:

```bash
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
```

**fzf note:** The `fzf --zsh` flag requires fzf 0.48.0+. Ubuntu/Debian repos ship an older version (0.44.1) that does not support it and will error with `unknown option: --zsh`. Use the explicit source approach above which works with any version.

Add zsh-completions fpath and source lines before `source $ZSH/oh-my-zsh.sh`:

```bash
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
```

Add these source lines right after `source $ZSH/oh-my-zsh.sh`:

```bash
source $HOME/.tmux/window-name.zsh
source $HOME/.aliasesrc
```

### 7b: Append the following to the end of `~/.zshrc`

Adapt paths/aliases to what you find in the user's bash config:

```bash
# Path
export PATH="./bin:$HOME/bin:$HOME/.local/bin:$HOME/.local/share/omakub/bin:/usr/local/bin:$PATH"
export PATH="$PATH:$(go env GOPATH)/bin"
export OMAKUB_PATH="$HOME/.local/share/omakub"

# Editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# File system aliases
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'batcat --style=numbers --color=always {}'"
alias fd='fdfind'
alias cd='z'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }
alias g='git'
alias d='docker'
alias r='rails'
alias bat='batcat'
alias lzg='lazygit'
alias lzd='lazydocker'

# Git aliases
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Tool initialization
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# History dedup
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

alias c8-start="$HOME/.tmuxp/start-all.sh"

# SSH agent - use a fixed socket so it works across all tmux sessions
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
if ! ssh-add -l &>/dev/null; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
  ssh-add "$HOME/.ssh/github" 2>/dev/null
fi
```

**Important:** When porting from bash, change `bash` to `zsh` in any `eval "$(tool activate bash)"` calls. Do not source bash-specific files (like `/usr/share/bash-completion/bash_completion`).

### 7c: Deploy `~/.aliasesrc` from dotfiles

```bash
cp ~/dotfiles/linux/zsh/.aliasesrc ~/.aliasesrc
```

This provides additional aliases: `md` (mkdir + cd), `listen`, `k` (kubectl), `t` (tmux), `tp` (tmuxp), `c` (clear), `d` (docker), `e` (exit), `v` (fzf file picker into nvim), `lg` (lazygit), `mockery2`, `c8-start`, and the `fut` function.

**Verify:** Run `zsh -c 'source ~/.zshrc && echo ok'` — must print `ok` without errors.

---

## Step 8: Configure Alacritty

**Goal:** Set Alacritty to use zsh as its shell and set font size to 13.

**Precondition:** Alacritty must be installed. Check with `which alacritty`.

### 8a: Find the Alacritty config

Look for config files in this order:
1. `~/.config/alacritty/alacritty.toml` (modern TOML format)
2. `~/.config/alacritty/alacritty.yml` (legacy YAML format)

The main config may use `import` to split settings across multiple files. Read the main config to discover which files contain `[shell]` and `[font]` settings.

### 8b: Set shell to zsh

Find the file containing the `[shell]` section. Replace the `program` value with `/usr/bin/zsh`:

```toml
[shell]
program = "/usr/bin/zsh"
```

If no `[shell]` section exists, add it.

### 8c: Set font size to 13

Find the file containing `[font]` with a `size` key. Set it to `13`:

```toml
[font]
size = 13
```

### 8d: Set Nerd Font family (if not already set)

Find or create the font family config:

```toml
[font]
normal = { family = "CaskaydiaMono Nerd Font", style = "Regular" }
bold = { family = "CaskaydiaMono Nerd Font", style = "Bold" }
italic = { family = "CaskaydiaMono Nerd Font", style = "Italic" }
```

**Verify:** Run `alacritty --print-all-events 2>&1 | head -1` or inspect the config files to confirm changes are syntactically valid TOML.

---

## Step 9: Configure GNOME Terminal

**Goal:** Set font to CaskaydiaMono Nerd Font at size 13 in GNOME Terminal.

**Precondition:** GNOME Terminal must be installed. Check with `which gnome-terminal`.

**Commands:**
```bash
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE}/ use-system-font false

gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE}/ font 'CaskaydiaMono Nerd Font 13'
```

**Verify:** Run the following and confirm it outputs `'CaskaydiaMono Nerd Font 13'`:
```bash
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE}/ font
```

---

## Step 10: Generate SSH key pair

**Goal:** Generate an Ed25519 SSH key pair for the user and display the public key so it can be added to GitHub, GitLab, remote servers, etc.

**Check first:** Run `ls ~/.ssh/id_ed25519.pub 2>/dev/null`. If the file exists, skip generation and just print the existing public key.

**Commands (if no key exists):**
```bash
ssh-keygen -t ed25519 -C "$USER" -f ~/.ssh/id_ed25519 -N ""
```

**Flags explained:**
- `-t ed25519` — use the Ed25519 algorithm (modern, fast, secure)
- `-C "$USER"` — comment/label for the key (use the username)
- `-f ~/.ssh/id_ed25519` — output file path
- `-N ""` — empty passphrase (no interactive prompt)

**Then print the public key:**
```bash
cat ~/.ssh/id_ed25519.pub
```

**Display the public key output to the user** so they can copy it to GitHub/GitLab/servers.

**Verify:** Both files must exist with correct permissions:
```bash
ls -la ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```
- `~/.ssh/id_ed25519` must be `-rw-------` (600)
- `~/.ssh/id_ed25519.pub` must be `-rw-r--r--` (644)

**Optional — add to ssh-agent:**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

## Step 11: Create project directory

**Goal:** Create the main project workspace directory at `~/projects/captiv8`.

**Commands:**
```bash
mkdir -p ~/projects/captiv8
```

**Verify:** Run `ls -d ~/projects/captiv8` — must return the path without error.

---

## Step 12: Install Kanata keyboard remapper

**Goal:** Clone the kanata-config repo, install the kanata binary, and set it up as a systemd service that starts at boot using the Linux config.

**Precondition:** Git and SSH must be configured (Steps 10 and the SSH public key must be added to GitHub). Also requires Step 1 (passwordless sudo).

### 12a: Add GitHub to known hosts

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
```

### 12b: Clone the kanata-config repo

```bash
git clone git@github.com:chris-toma/kanata-config.git ~/projects/kanata-config
```

**Verify:** `ls ~/projects/kanata-config/linux-config.kbd` must exist.

### 12c: Install the kanata binary

```bash
chmod +x ~/projects/kanata-config/bin/kanata
sudo cp ~/projects/kanata-config/bin/kanata /usr/local/bin/kanata
```

**Verify:** `kanata --version` must return a version string.

### 12d: Set up uinput permissions

Kanata needs access to `/dev/uinput` for virtual keyboard input.

```bash
sudo groupadd -f uinput
sudo usermod -aG input,uinput $USER
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo modprobe uinput
```

### 12e: Create systemd service

**Important:** Use a **system-level** service (not user-level) because kanata needs root access to input devices.

Create the file `/etc/systemd/system/kanata.service`:

```ini
[Unit]
Description=Kanata keyboard remapper
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/local/bin/kanata -c /home/USERNAME/projects/kanata-config/linux-config.kbd
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Important:** Replace `USERNAME` in the `ExecStart` path with the actual username (`$USER`).

**Commands to install and enable:**
```bash
sudo cp kanata.service /etc/systemd/system/kanata.service
sudo systemctl daemon-reload
sudo systemctl enable kanata.service
sudo systemctl start kanata.service
```

### 12f: Verify

```bash
sudo systemctl status kanata.service
```

Output must show `Active: active (running)`. Check logs for errors with:
```bash
journalctl -u kanata.service --no-pager -n 20
```

**Troubleshooting:**
- If you see `Permission denied` on uinput: the udev rule or `modprobe uinput` may not have taken effect. Reboot and try again.
- If using a user-level service (`systemctl --user`): it will fail because user services don't have access to `/dev/uinput` even with group membership until re-login. Use the system-level service instead.

---

## Step 13: Clone project repos into captiv8

**Goal:** Clone the Captiv8 project repositories into `~/projects/captiv8`.

**Precondition:** SSH key must be generated (Step 10) and added to GitHub. GitHub must be in known hosts (Step 12a).

### 13a: Clone go-microservice-env

```bash
git clone git@github.com:chris-toma/go-microservice-env.git ~/projects/captiv8/go-microservice-env
```

**Verify:** Run `ls ~/projects/captiv8/go-microservice-env/` — must contain project files (e.g. `README.md`, `scripts/`, `services/`).

### 13b: Clone go-microservices

```bash
git clone git@github.com:captiv8io/go-microservices.git ~/projects/captiv8/go-microservices
```

**Verify:** Run `ls ~/projects/captiv8/go-microservices/` — must contain project files (e.g. `README.md`, `go.mod`, `services/`, `internal/`).

---

## Step 14: Install buf and mockery

**Goal:** Install `buf` (Protocol Buffers toolchain) and `mockery` (Go mock code generator) via `go install`.

**Precondition:** Go must be installed (e.g. via mise).

**Commands:**
```bash
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/vektra/mockery/v3@latest
```

**Verify:** Run `buf --version` — must return a version (e.g. `1.65.0`). Run `mockery version` — must return a version (e.g. `v3.6.4`).

**Note:** The binaries are installed to `$(go env GOPATH)/bin`. Ensure this directory is in your `PATH` (it is added in Step 7b).

---

## Step 15: Install tmux, tmuxp, and stow

**Goal:** Install tmux (terminal multiplexer), tmuxp (tmux session manager), and GNU stow (symlink farm manager for dotfiles).

**Commands:**
```bash
sudo apt install -y tmux stow
pip install --user tmuxp
```

**Verify:** Run `tmux -V` — must return a version (e.g. `tmux 3.4`). Run `tmuxp --version` — must return a version (e.g. `tmuxp 1.64.0`). Run `stow --version` — must return a version.

**Note:** If `pip install --user` fails, try `pipx install tmuxp` instead.

---

## Step 16: Clone dotfiles and deploy configs with stow

**Goal:** Clone the dotfiles repo and use GNU stow to create symlinks for tmux, tmuxp, and aliases configs.

**Precondition:** SSH key must be generated (Step 10) and added to GitHub. GitHub must be in known hosts (Step 12a). tmux, tmuxp, and stow must be installed (Step 15).

### 16a: Clone the dotfiles repo

```bash
git clone git@github.com:chris-toma/dotfiles.git ~/dotfiles
```

**Verify:** `ls ~/dotfiles/linux/` — must contain `zsh/`, `tmux/`, and `tmuxp/` directories.

### 16b: Stow tmux config

This creates symlinks for `~/.tmux.conf` and `~/.tmux/` (which contains the window-naming hook).

```bash
cd ~/dotfiles && stow tmux -t ~
```

The window-naming hook (`~/.tmux/window-name.zsh`) automatically renames tmux windows based on the current directory and running command (e.g. `nvim-projectname`, `claude-projectname`). Windows marked with `@managed` (set by tmuxp) are left alone.

**Verify:**
```bash
file ~/.tmux.conf ~/.tmux
```
Both must show as `symbolic link to dotfiles/tmux/...`.

### 16c: Stow tmuxp session configs

```bash
cd ~/dotfiles/linux && stow tmuxp -t ~
```

This symlinks `~/.tmuxp/` which contains:
- `master.yaml` — the main tmuxp session with all Captiv8 microservices
- `start-all.sh` — comprehensive startup script (checks Docker, RabbitMQ, project directory, then loads master.yaml)
- `start-dependencies.sh` — starts just Docker and RabbitMQ
- `retry-service.sh` — retry wrapper with exponential backoff for service startup
- `aliases.sh` — the `c8-start` alias loader

**Verify:**
```bash
file ~/.tmuxp
```
Must show as `symbolic link to dotfiles/linux/tmuxp/.tmuxp`.

### 16d: Stow zsh aliases

Stow the `linux/zsh` package but ignore `.zshrc` (we maintain our own customized version):

```bash
cd ~/dotfiles/linux && stow zsh -t ~ --ignore='\.zshrc'
```

This creates a symlink for `~/.aliasesrc` without touching `~/.zshrc`.

**Verify:** `file ~/.aliasesrc` — must show as a symbolic link to `dotfiles/linux/zsh/.aliasesrc`.

### 16e: Install TPM (Tmux Plugin Manager) and plugins

The `.tmux.conf` uses TPM to manage plugins. Install TPM:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then install all plugins defined in `.tmux.conf`:

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```

This installs:
- `tmux-sensible` — sensible default settings
- `vim-tmux-navigator` — seamless Ctrl+hjkl navigation between tmux panes and vim splits
- `tmux-fzf` — fzf integration for tmux (press `prefix + F` to launch)
- `minimal-tmux-status` — clean minimal status bar theme

**Verify:**
```bash
ls ~/.tmux/plugins/
```
Must contain: `tpm/`, `tmux-sensible/`, `vim-tmux-navigator/`, `tmux-fzf/`, `minimal-tmux-status/`.

To start all services: run `c8-start` (or `~/.tmuxp/start-all.sh`).

---

## Step 17: Configure Logitech MX Master mouse (LogiOps)

**Goal:** Configure the Logitech MX Master mouse using `logiops` (`logid`) so the thumb button opens GNOME Activities (Super key), while back/forward side buttons retain their default behavior.

**Precondition:** `logiops` must be installed. Check with `logid --version`.

### 17a: Install logiops (if not installed)

```bash
sudo apt install -y logiops
```

### 17b: Write the config

Create/replace `/etc/logid.cfg` with:

```cfg
devices: (
{
    name: "Wireless Mouse MX Master";
    smartshift:
    {
        on: true;
        threshold: 15;
    };
    hiresscroll:
    {
        hires: true;
        invert: false;
        target: false;
    };
    dpi: 1000;

    buttons: (
        {
            cid: 0xc3;
            action =
            {
                type: "Keypress";
                keys: ["KEY_LEFTMETA"];
            };
        }
    );
}
);
```

**Important notes:**
- Only remap the thumb button (`0xc3`). Do **not** remap the back (`0x53`) and forward (`0x56`) side buttons — explicitly remapping them can break their default behavior on Wayland.
- The original MX Master does not support raw XY diversion on `0xc3`, so gesture-type actions (hold + swipe) will not work. Use a simple `Keypress` instead.
- The device name must be `"Wireless Mouse MX Master"` (not `"MX Master"` or other variants). Run `logid -v` to confirm the detected name.

### 17c: Enable and restart the service

```bash
sudo systemctl enable logid
sudo systemctl restart logid
```

### 17d: Verify

```bash
systemctl status logid
```

Output must show `Active: active (running)`. Check logs for errors:

```bash
journalctl -u logid --no-pager -n 20
```

Run `logid -v` (after stopping the service) to confirm button mappings are applied and no warnings appear.

---

## Post-setup notes for the user

After all steps are complete, inform the user:

1. **Log out and log back in** (or reboot) for the default shell change to take effect.
2. **On first zsh launch**, the Powerlevel10k configuration wizard will run automatically. Follow its prompts to choose a prompt style. It can be re-run anytime with `p10k configure`.
3. **Passwordless sudo is a security trade-off.** It should only be used on personal/development machines, never on shared or production servers.
4. **Copy the SSH public key** to any services you need (GitHub, GitLab, remote servers). On GitHub: Settings > SSH and GPG keys > New SSH key.
5. **Kanata** is running as a system service. To reload after config changes: `sudo systemctl restart kanata.service`. To stop: `sudo systemctl stop kanata.service`.
