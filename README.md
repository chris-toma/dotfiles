# dotfiles

## tmux
```bash
# Clone TPM into the tmux plugins directory
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
```bash
Ctrl + s + I # Install plugins
Ctrl + r # Reload tmux environment
Ctrl + s + U # Update plugins
```

## zsh
```bash
# Clone oh-my-zsh if not already installed
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Go to custom plugins directory
cd $ZSH_CUSTOM/plugins

# Install Git History
git clone https://github.com/johnhamelink/git-history.git

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions.git

# Install zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode.git

# Install zsh-easy-motion
git clone https://github.com/IngoHeimbach/zsh-easy-motion.git
```