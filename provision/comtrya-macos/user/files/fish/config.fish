/opt/homebrew/bin/starship init fish | source
/opt/homebrew/bin/mise activate fish | source
/opt/homebrew/bin/zoxide init fish | source
/opt/homebrew/bin/atuin init fish | source
eval "$(/opt/homebrew/bin/brew shellenv)"
alias cat="bat"
alias l="eza --time-style=long-iso --color=auto --classify=always"
alias ll="l -ahl"
alias la="l -a"
alias k="kubectl"
alias dc="docker compose"
alias mise_up="mise outdated --bump --json | jq -r 'map(\"\(.name)@\(.latest)\") | join(\" \")'"
