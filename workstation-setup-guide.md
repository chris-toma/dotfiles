# AI Agent Plan: Workstation Setup

You are setting up a Linux (Ubuntu/Debian) development machine with zsh, Sheldon, Starship, and development tools. Follow these steps **in order**. Each step has preconditions, exact commands, and a verification check. Do not skip verifications.

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

## Step 2: Generate SSH key pair

**Goal:** Generate an Ed25519 SSH key pair for the user and display the public key so it can be added to GitHub, GitLab, remote servers, etc.

**Check first:** Run `ls ~/.ssh/id_ed25519.pub 2>/dev/null`. If the file exists, skip generation and just print the existing public key.

**Commands (if no key exists):**
```bash
ssh-keygen -t ed25519 -C "$USER" -f ~/.ssh/id_ed25519 -N ""
```

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

## Step 3: Add GitHub to known hosts

**Goal:** Allow SSH connections to GitHub without interactive host key confirmation.

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
```

**Verify:** Run `ssh -T git@github.com` — must show `Hi USERNAME! You've successfully authenticated`.

**Precondition:** The SSH public key from Step 2 must already be added to GitHub (Settings > SSH and GPG keys > New SSH key). Inform the user to do this manually before proceeding.

---

## Step 4: Clone dotfiles repo

**Goal:** Clone the dotfiles repo. Many later steps depend on files from this repo.

**Check first:** Run `ls ~/dotfiles/.git 2>/dev/null`. If it exists, skip this step.

```bash
git clone git@github.com:chris-toma/dotfiles.git ~/dotfiles
```

**Verify:** `ls ~/dotfiles/zsh/install.sh` — must exist.

---

## Step 5: Install a Nerd Font

**Goal:** Install CaskaydiaMono Nerd Font for terminal icons (used by eza, starship, etc.).

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

## Step 6: Install fzf from GitHub releases

**Goal:** Install a recent version of fzf (0.48.0+). The dotfiles `.zshrc` uses `source <(fzf --zsh)` which requires fzf 0.48.0+. Ubuntu/Debian repos ship 0.44.1 which does not support this flag.

**Check first:** Run `fzf --version`. If the version is 0.48.0 or higher, skip this step.

**Commands:**
```bash
FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
curl -fLo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
sudo tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin
rm /tmp/fzf.tar.gz
```

**Verify:** Run `fzf --version` — must show 0.48.0 or higher. Run `fzf --zsh` — must produce output (not an error).

---

## Step 7: Install zsh and shell tools

**Goal:** Install zsh, Sheldon (plugin manager), Starship (prompt), and all shell dependencies. Then deploy the zsh dotfiles and set zsh as the default shell.

**Precondition:** Dotfiles repo must be cloned (Step 4). fzf must be 0.48.0+ (Step 6).

The dotfiles repo includes an install script at `~/dotfiles/zsh/install.sh` that handles everything:

```bash
~/dotfiles/zsh/install.sh
```

This script:
1. Installs dependencies: zsh, fzf, stow, go, fd, eza, zoxide, yazi, lazygit, neovim, starship, sheldon
2. Symlinks the starship config from `~/dotfiles/omarchy/.config/starship.toml`
3. Stows the zsh config package (`~/.zshrc`, `~/.aliasesrc`, `~/.config/sheldon/plugins.toml`)
4. Runs `sheldon lock` to initialize plugins (zsh-syntax-highlighting, zsh-autosuggestions, zsh-vi-mode)
5. Sets zsh as the default shell via `chsh`

**If the script fails** or you prefer to do it manually, here are the individual steps:

### 7a: Install zsh

```bash
sudo apt update && sudo apt install -y zsh
```

### 7b: Install starship

```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

### 7c: Install sheldon

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install sheldon
```

### 7d: Install other dependencies

```bash
sudo apt install -y stow fd-find eza zoxide
```

### 7e: Link starship config

```bash
mkdir -p ~/.config
ln -sf ~/dotfiles/omarchy/.config/starship.toml ~/.config/starship.toml
```

### 7f: Stow zsh config

```bash
cd ~/dotfiles && stow -v --restow zsh
```

This creates symlinks for:
- `~/.zshrc` → `dotfiles/zsh/.zshrc`
- `~/.aliasesrc` → `dotfiles/zsh/.aliasesrc`
- `~/.config/sheldon/plugins.toml` → `dotfiles/zsh/.config/sheldon/plugins.toml`

### 7g: Initialize sheldon plugins

```bash
sheldon lock
```

### 7h: Set zsh as default shell

```bash
sudo chsh -s $(which zsh) $USER
```

**Verify:**
```bash
grep "^$USER:" /etc/passwd
```
The last field must be `/usr/bin/zsh`.

```bash
file ~/.zshrc ~/.aliasesrc ~/.config/sheldon
```
All must show as symbolic links into `dotfiles/zsh/...`.

```bash
TERM=xterm-256color zsh -c 'source ~/.zshrc && echo ok'
```
Must print `ok` without errors.

**Note:** The shell change takes effect on next login/reboot, not in the current session.

### What the `.zshrc` does

The dotfiles `.zshrc` (managed via stow, do not edit directly — edit `~/dotfiles/zsh/.zshrc` instead):

- Detects OS (macOS/Linux) and sets up Homebrew on macOS
- Disables auto-title (`DISABLE_AUTO_TITLE`)
- Initializes fzf via `source <(fzf --zsh)`
- Loads completions (`compinit`)
- Loads plugins via **Sheldon**: zsh-syntax-highlighting, zsh-autosuggestions, zsh-vi-mode
- Sources `~/.tmux/window-name.zsh` (tmux window auto-renaming)
- Sources `~/.aliasesrc` (shared aliases)
- Adds `~/bin`, `~/.local/bin`, and `$(go env GOPATH)/bin` to `PATH`
- Configures history deduplication
- Initializes **Starship** prompt
- Initializes **zoxide** (smart cd)
- Binds `Alt+F` to zoxide interactive selection (`zi`)

### What `~/.aliasesrc` provides

- Navigation: `..`, `...`, `....`, `.....`
- Tools: `n` (nvim), `v` (fzf→nvim), `y` (yazi), `lg` (lazygit), `k` (kubectl), `t` (tmux), `tp` (tmuxp), `c` (clear), `d` (docker), `e` (exit)
- File listing: `l`, `ls`, `ll` (all using eza with icons)
- Utilities: `md` (mkdir + cd), `listen` (OS-aware port listener), `c8-start` (tmuxp startup)
- Project: `fut` function (runs `./fut` in go-microservices)

---

## Step 8: Configure terminal emulators

**Goal:** Set all installed terminal emulators to use zsh as the shell, CaskaydiaMono Nerd Font, and font size 13.

**Discovery:** Run the following to detect which terminals are installed, then configure only those present:
```bash
for term in alacritty ghostty kitty wezterm foot konsole gnome-terminal xfce4-terminal tilix terminator; do
  which $term 2>/dev/null && echo "  -> FOUND: $term"
done
```

---

### 8a: Configure Alacritty

**Precondition:** Check with `which alacritty`. Skip if not installed.

**Find the config:** Look in this order:
1. `~/.config/alacritty/alacritty.toml` (modern TOML format)
2. `~/.config/alacritty/alacritty.yml` (legacy YAML format)

The main config may use `import` to split settings across multiple files. Read the main config to discover which files contain `[shell]` and `[font]` settings.

**Set shell to zsh:** Find or create the `[shell]` section:

```toml
[shell]
program = "/usr/bin/zsh"
```

**Set font family and size to 13:**

```toml
[font]
normal = { family = "CaskaydiaMono Nerd Font", style = "Regular" }
bold = { family = "CaskaydiaMono Nerd Font", style = "Bold" }
italic = { family = "CaskaydiaMono Nerd Font", style = "Italic" }
size = 13
```

**Verify:** Inspect the config file to confirm valid TOML syntax.

---

### 8b: Configure Ghostty

**Precondition:** Check with `which ghostty`. Skip if not installed.

**Config location:** `~/.config/ghostty/config` (plain key-value format, one setting per line).

**Set font family and size to 13:** Find and update (or add) these lines:

```
font-family = "CaskaydiaMono Nerd Font"
font-size = 13
```

Ghostty uses zsh automatically if it is the user's default shell (Step 7), so no explicit shell setting is needed.

**Verify:** Run `ghostty +show-config | grep -E 'font-family|font-size'` — must show `CaskaydiaMono Nerd Font` and `13`.

---

### 8c: Configure GNOME Terminal (if installed)

**Precondition:** Check with `which gnome-terminal`. Skip if not installed.

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

## Step 9: Create project directory

**Goal:** Create the main project workspace directory at `~/projects/captiv8`.

**Commands:**
```bash
mkdir -p ~/projects/captiv8
```

**Verify:** Run `ls -d ~/projects/captiv8` — must return the path without error.

---

## Step 10: Install Kanata keyboard remapper

**Goal:** Clone the kanata-config repo, install the kanata binary, and set it up as a systemd service that starts at boot using the Linux config.

**Precondition:** Git and SSH must be configured (Steps 2–3 and the SSH public key must be added to GitHub). Also requires Step 1 (passwordless sudo).

### 10a: Clone the kanata-config repo

```bash
git clone git@github.com:chris-toma/kanata-config.git ~/projects/kanata-config
```

**Verify:** `ls ~/projects/kanata-config/linux-config.kbd` must exist.

### 10b: Install the kanata binary

```bash
chmod +x ~/projects/kanata-config/bin/kanata
sudo cp ~/projects/kanata-config/bin/kanata /usr/local/bin/kanata
```

**Verify:** `kanata --version` must return a version string.

### 10c: Set up uinput permissions

Kanata needs access to `/dev/uinput` for virtual keyboard input.

```bash
sudo groupadd -f uinput
sudo usermod -aG input,uinput $USER
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo modprobe uinput
```

### 10d: Create systemd service

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
sudo systemctl daemon-reload
sudo systemctl enable kanata.service
sudo systemctl start kanata.service
```

### 10e: Verify

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

## Step 11: Clone project repos into captiv8

**Goal:** Clone the Captiv8 project repositories into `~/projects/captiv8`.

**Precondition:** SSH key must be generated (Step 2) and added to GitHub. GitHub must be in known hosts (Step 3).

### 11a: Clone go-microservice-env

```bash
git clone git@github.com:chris-toma/go-microservice-env.git ~/projects/captiv8/go-microservice-env
```

**Verify:** Run `ls ~/projects/captiv8/go-microservice-env/` — must contain project files (e.g. `README.md`, `scripts/`, `services/`).

### 11b: Clone go-microservices

```bash
git clone git@github.com:captiv8io/go-microservices.git ~/projects/captiv8/go-microservices
```

**Verify:** Run `ls ~/projects/captiv8/go-microservices/` — must contain project files (e.g. `README.md`, `go.mod`, `services/`, `internal/`).

---

## Step 12: Install buf and mockery

**Goal:** Install `buf` (Protocol Buffers toolchain) and `mockery` (Go mock code generator) via `go install`.

**Precondition:** Go must be installed (e.g. via mise). `$(go env GOPATH)/bin` must be in `PATH` (it is added in the dotfiles `.zshrc`).

**Commands:**
```bash
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/vektra/mockery/v3@latest
```

**Verify:** Run `buf --version` — must return a version. Run `mockery version` — must return a version.

---

## Step 13: Install tmux and tmuxp

**Goal:** Install tmux (terminal multiplexer) and tmuxp (tmux session manager).

**Note:** `stow` is already installed by the zsh install script (Step 7).

**Commands:**
```bash
sudo apt install -y tmux
pip install --user tmuxp
```

**Verify:** Run `tmux -V` — must return a version (e.g. `tmux 3.4`). Run `tmuxp --version` — must return a version (e.g. `tmuxp 1.64.0`).

**Note:** If `pip install --user` fails, try `pipx install tmuxp` instead.

---

## Step 14: Deploy tmux and tmuxp configs with stow

**Goal:** Use GNU stow to create symlinks for tmux and tmuxp configs, then install TPM and tmux plugins.

**Precondition:** Dotfiles repo must be cloned (Step 4). tmux and tmuxp must be installed (Step 13).

### 14a: Stow tmux config

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

### 14b: Stow tmuxp session configs

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

### 14c: Install TPM (Tmux Plugin Manager) and plugins

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

## Step 15: Configure Logitech MX Master mouse (LogiOps)

**Goal:** Configure the Logitech MX Master mouse using `logiops` (`logid`) so the thumb button opens GNOME Activities (Super key), while back/forward side buttons retain their default behavior.

**Precondition:** `logiops` must be installed. Check with `logid --version`.

### 15a: Install logiops (if not installed)

```bash
sudo apt install -y logiops
```

### 15b: Write the config

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

### 15c: Enable and restart the service

```bash
sudo systemctl enable logid
sudo systemctl restart logid
```

### 15d: Verify

```bash
systemctl status logid
```

Output must show `Active: active (running)`. Check logs for errors:

```bash
journalctl -u logid --no-pager -n 20
```

Run `logid -v` (after stopping the service) to confirm button mappings are applied and no warnings appear.

---

## Step 16: Install Slack

**Goal:** Install the Slack desktop client for team communication.

**Check first:** Run `which slack`. If it returns a path, skip this step.

**Commands (Ubuntu/Debian):**
```bash
curl -fLo /tmp/slack.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/4.47.69/slack-desktop-4.47.69-amd64.deb
sudo dpkg -i /tmp/slack.deb
sudo apt install -f -y
rm /tmp/slack.deb
```

**Verify:** Run `which slack` — must return a path.

---

## Step 17: Install GoLand

**Goal:** Install JetBrains GoLand IDE for Go development.

**Check first:** Run `which goland`. If it returns a path, skip this step.

**Commands (Ubuntu/Debian):**
```bash
sudo snap install goland --classic
```

Alternatively, download from https://www.jetbrains.com/go/download/ or install via the JetBrains Toolbox App.

**Verify:** Run `which goland` — must return a path.

---

## Step 18: Install Postman

**Goal:** Install Postman for API testing and development.

**Check first:** Run `which postman`. If it returns a path, skip this step.

**Commands (Ubuntu/Debian):**
```bash
curl -fLo /tmp/postman-linux-x64.tar.gz https://dl.pstmn.io/download/latest/linux_64
sudo tar -xzf /tmp/postman-linux-x64.tar.gz -C /opt
sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman
rm /tmp/postman-linux-x64.tar.gz
```

**Verify:** Run `which postman` — must return a path.

---

## Step 19: Configure Hyprland keyboard shortcuts

**Goal:** Add Alt + number shortcuts to quickly launch frequently used applications.

**Precondition:** Hyprland must be the active compositor. Check with `echo $XDG_CURRENT_DESKTOP` — must return `Hyprland`. If running GNOME or another DE, skip this step entirely.

### 19a: Find the bindings config

Hyprland splits config across files in `~/.config/hypr/`. The keybindings file is:
```
~/.config/hypr/bindings.conf
```

### 19b: Add quick-launch bindings

Append the following to `~/.config/hypr/bindings.conf`:

```bash
# Quick-launch apps with Alt + number
bindd = ALT, 1, Chrome, exec, uwsm-app -- google-chrome-stable
bindd = ALT, 2, Ghostty, exec, uwsm-app -- ghostty
bindd = ALT, 3, GoLand, exec, uwsm-app -- goland
bindd = ALT, 4, Slack, exec, uwsm-app -- slack
bindd = ALT, 9, Postman, exec, uwsm-app -- postman
```

**Notes:**
- `bindd` provides a description (3rd field) that shows up in `hyprctl binds`.
- `uwsm-app --` ensures the app launches under the Wayland session manager correctly.
- Alt+5 through Alt+8 are left free for future use.

### 19c: Reload Hyprland

Hyprland live-reloads config on save, so no manual reload is needed. To force a reload:
```bash
hyprctl reload
```

**Verify:** Run `hyprctl binds | grep -A2 'ALT.*[1-9]'` — must show the five bindings. Press Alt+1 to confirm Chrome launches.

---

## Post-setup notes for the user

After all steps are complete, inform the user:

1. **Log out and log back in** (or reboot) for the default shell change to take effect.
2. **Passwordless sudo is a security trade-off.** It should only be used on personal/development machines, never on shared or production servers.
3. **Copy the SSH public key** to any services you need (GitHub, GitLab, remote servers). On GitHub: Settings > SSH and GPG keys > New SSH key.
4. **Kanata** is running as a system service. To reload after config changes: `sudo systemctl restart kanata.service`. To stop: `sudo systemctl stop kanata.service`.
5. **Do not edit `~/.zshrc` directly** — it is a symlink to `~/dotfiles/zsh/.zshrc`. Edit the file in the dotfiles repo and changes will take effect immediately.
