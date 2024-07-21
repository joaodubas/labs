export LOCAL_BIN_HOME={$HOME}/.local/bin
export LOCAL_SRC_HOME={$HOME}/.local/src
export XDG_CONFIG_HOME={$HOME}/.config
export XDG_DATA_HOME={$HOME}/.local/share
export XDG_CACHE_HOME={$HOME}/.cache
export STARSHIP_CONFIG={$XDG_CONFIG_HOME}/starship/config.toml
export ATUIN_BIN={$HOME}/.atuin/bin
export PATH={$LOCAL_BIN_HOME}:{$ATUIN_BIN}:$PATH
export MISE_ENV_FILE=.env
{$LOCAL_BIN_HOME}/starship init fish | source
{$LOCAL_BIN_HOME}/mise activate fish | source
{$LOCAL_BIN_HOME}/zoxide init fish | source
{$HOME}/.atuin/bin/atuin init fish | source
alias cat="bat"
alias l="eza --time-style=long-iso --color=auto --classify=always"
alias ll="l -ahl"
alias la="l -a"
alias k="kubectl"
alias dc="docker compose"
alias nh="nvim --listen 0.0.0.0:6666 --headless &> /dev/null"
