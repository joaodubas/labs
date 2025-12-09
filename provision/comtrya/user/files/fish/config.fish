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
# Explanation:
# - `mise outdated --bump --json`: This part generates the JSON output of outdated dependencies.
# - `jq -r '...'`: jq is used to process JSON data. The -r flag outputs raw strings without JSON quoting.
# -` map("\(.name)@\(.latest)")`: This iterates over each object in the JSON array. For each object, it constructs a string in the format "name@version" using the name and latest fields.
# - `join(" ")`: This takes the array of "name@version" strings and joins them into a single string, with each item separated by a space.
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
    bind -M insert \es sesh-sessions
    # Default (command) mode binding
    bind -M default \es sesh-sessions
    # Optionally, for visual mode if you use it extensively
    # bind -M visual \es sesh-sessions
end
