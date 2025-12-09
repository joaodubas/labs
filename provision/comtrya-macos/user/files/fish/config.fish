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

function sesh-sessions
    # Run sesh list and pipe to fzf to allow interactive selection.
    # The output of fzf (the selected session) is captured into the 'session' variable.
    set -l session (sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')

    # Repaint the command line to clear any fzf output artifacts.
    commandline -f repaint

    # If a session was selected (i.e., the 'session' variable is not empty), connect to it.
    if test -n "$session"
        sesh connect $session
    end
end

function fish_user_key_bindings
    # Insert mode binding
    bind -M insert \cs sesh-sessions
    # Default (command) mode binding
    bind -M default \cs sesh-sessions
    # Optionally, for visual mode if you use it extensively
    # bind -M visual \cs sesh-sessions
end
