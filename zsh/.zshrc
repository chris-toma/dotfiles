# OS detection
case "$(uname -s)" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
esac

if [[ "$OS" == "mac" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export DISABLE_AUTO_TITLE='true'

source <(fzf --zsh)

autoload -U compinit && compinit

eval "$(sheldon source)"

source $HOME/.tmux/window-name.zsh
source $HOME/.aliasesrc
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
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

if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# SSH agent - use a fixed socket so it works across all tmux sessions (Linux only, macOS uses keychain)
if [[ "$OS" == "linux" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
  if ! ssh-add -l &>/dev/null; then
    rm -f "$SSH_AUTH_SOCK"
    eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
    ssh-add "$HOME/.ssh/github" 2>/dev/null
  fi
fi

eval "$(zoxide init zsh)"

zoxide-widget() { zi; zle reset-prompt }
zle -N zoxide-widget

zvm_after_init() {
  bindkey '\ef' zoxide-widget
  bindkey -M vicmd '\ef' zoxide-widget
}
eval "$(starship init zsh)"
