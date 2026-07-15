# DoorAPI shell config

# PATH
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:$PATH"

# Mise
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
fi

# Bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# History
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar 2>/dev/null || true
shopt -s autocd 2>/dev/null || true
shopt -s cdspell 2>/dev/null || true
shopt -s dirspell 2>/dev/null || true

# Colors
export CLICOLOR=1
export LS_COLORS="${LS_COLORS:-di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33}"

# Prompt
parse_git_branch() {
    git branch --show-current 2>/dev/null
}

doorapi_prompt() {
    local exit_code=$?
    local branch
    branch="$(parse_git_branch)"

    local reset="\[\e[0m\]"
    local pink="\[\e[1;35m\]"
    local blue="\[\e[1;34m\]"
    local yellow="\[\e[1;33m\]"
    local red="\[\e[1;31m\]"

    if [ -n "$branch" ]; then
        PS1="${pink}\u@\h ${blue}\w ${yellow}(${branch})${reset}\n\$ "
    else
        PS1="${pink}\u@\h ${blue}\w${reset}\n\$ "
    fi

    if [ "$exit_code" -ne 0 ]; then
        PS1="${red}[${exit_code}]${reset} ${PS1}"
    fi
}

PROMPT_COMMAND=doorapi_prompt

# Basic aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias ports='ss -tulpn'

# DoorAPI aliases
alias doorapi='cd ~/doorapi'
alias api='cd ~/doorapi/device_api'
alias front='cd ~/doorapi/doorapi_front'
alias mobile='cd ~/doorapi/doorapi_mobile'
alias thirdparty='cd ~/doorapi/thirdparty_api'
alias k8s='cd ~/doorapi/doorapi-k8s'
alias localdev='cd ~/doorapi/doorapi-dev-local'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Elixir aliases
alias m='mix'
alias mt='mix test'
alias mf='mix format'
alias mc='mix compile'
alias ips='iex -S mix phx.server'

# Podman aliases
alias p='podman'
alias pps='podman ps'
alias pi='podman images'
alias pl='podman logs'
alias px='podman exec -it'

# Kubernetes aliases
alias k='kubectl'

# Completion
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi

if command -v podman >/dev/null 2>&1; then
    source <(podman completion bash)
fi

if command -v gh >/dev/null 2>&1; then
    source <(gh completion -s bash)
fi

if command -v npm >/dev/null 2>&1; then
    source <(npm completion 2>/dev/null) 2>/dev/null || true
fi

# fzf
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='find . -type f 2>/dev/null'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi