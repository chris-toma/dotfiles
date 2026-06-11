[[ "$TERM" == "xterm-ghostty" ]] && export TERM=xterm-256color

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

eval "$(starship init zsh)"

eval "$(zoxide init zsh)"

zoxide-widget() { zi; zle reset-prompt }
zle -N zoxide-widget

zvm_after_init() {
  bindkey '\ef' zoxide-widget
  bindkey -M vicmd '\ef' zoxide-widget
}
