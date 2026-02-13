# Tmux window naming hook
# Source this from .zshrc: source ~/.tmux/window-name.zsh

# Only activate inside tmux
[[ -n "$TMUX" ]] || return

_tmux_set_window_name() {
  tmux rename-window -t "$TMUX_PANE" "$1"
}

_tmux_window_precmd() {
  _tmux_set_window_name "${PWD##*/}"
}

_tmux_window_preexec() {
  local cmd="${1%% *}"
  local dir="${PWD##*/}"

  case "$cmd" in
    claude) _tmux_set_window_name "claude-${dir}" ;;
    cursor|agent) _tmux_set_window_name "cursor-${dir}" ;;
    nvim|n|v) _tmux_set_window_name "nvim-${dir}" ;;
  esac
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tmux_window_precmd
add-zsh-hook preexec _tmux_window_preexec
