export ZSH="$HOME/.oh-my-zsh"
export DISABLE_AUTO_TITLE='true'
set -o vi

source <(fzf --zsh)

plugins=(git history zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode zsh-easy-motion)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh
source $HOME/.tmux/window-name.zsh
source $HOME/.aliasesrc
source $HOME/.bash_profile
export PATH="/Users/christoma/bin:$PATH"

set number
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/bin:/usr/local/bin:$PATH
alias axbrew='arch -x86_64 /usr/local/homebrew/bin/brew'
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PATH="$PATH:$(go env GOPATH)/bin"

HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

if [ -f '/Users/christoma/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/christoma/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/christoma/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/christoma/google-cloud-sdk/completion.zsh.inc'; fi
alias c8-start="/Users/christoma/.tmuxp/start-all.sh"
export PATH="$HOME/.local/bin:$PATH"

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
if ! ssh-add -l &>/dev/null; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
  ssh-add "$HOME/.ssh/github" 2>/dev/null
fi

eval "$(starship init zsh)"
