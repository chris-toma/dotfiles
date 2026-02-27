eval "$(/opt/homebrew/bin/brew shellenv)"
export DISABLE_AUTO_TITLE='true'

source <(fzf --zsh)

autoload -U compinit && compinit

eval "$(sheldon source)"

source $HOME/.tmux/window-name.zsh
source $HOME/.aliasesrc
export PATH="/Users/christoma/bin:$PATH"

export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
alias axbrew='arch -x86_64 /usr/local/homebrew/bin/brew'
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PATH="$PATH:$(go env GOPATH)/bin"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=1000000
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
export PATH="$HOME/.local/bin:$PATH"

export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
if ! ssh-add -l &>/dev/null; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
  ssh-add "$HOME/.ssh/github" 2>/dev/null
fi

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
