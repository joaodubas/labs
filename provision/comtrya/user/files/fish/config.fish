$LOCAL_BIN_HOME/starship init fish | source
$LOCAL_BIN_HOME/mise activate fish | source
$LOCAL_BIN_HOME/zoxide init fish | source
# NOTE: (jpd) Since the `-k` flag is no longer supported in `bind`, I'm removing it manually.
$ATUIN_BIN/atuin init fish | sed 's/-k up/up/g' | source
alias cat="bat"
alias l="eza --time-style=long-iso --color=auto --classify=always"
alias ll="l -ahl"
alias la="l -a"
alias k="kubectl"
alias dc="docker compose"
alias nh="nvim --listen 0.0.0.0:6666 --headless &> /dev/null"
