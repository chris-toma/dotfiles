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

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$(go env GOPATH)/bin"

source <(fzf --zsh)

autoload -U compinit && compinit

eval "$(sheldon source)"

source $HOME/.tmux/window-name.zsh
source $HOME/.aliasesrc

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
export PATH=/usr/local/go/bin:$PATH

# opencode
export PATH=/home/prod/.opencode/bin:$PATH
# LITELLM_API_KEY lives in ~/.zshenv, which zsh sources automatically and which
# is not part of this repo.

# claude code via teramind litellm proxy
claude-tm() {
  ANTHROPIC_BASE_URL="https://ikwork.teramind.co:4000" \
  ANTHROPIC_AUTH_TOKEN="$LITELLM_API_KEY" \
  ANTHROPIC_MODEL="kimi-k3-usa" \
  ANTHROPIC_SMALL_FAST_MODEL="gpt-oss-120b" \
  command claude --model kimi-k3-usa "$@"
}
alias cd-tm='claude-tm'
