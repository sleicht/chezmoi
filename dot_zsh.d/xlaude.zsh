# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#compdef xlaude

_xlaude() {
    local -a commands
    commands=(
        'create:Create a new git worktree'
        'open:Open an existing worktree and launch Claude'
        'delete:Delete a worktree and clean up'
        'add:Add current worktree to xlaude management'
        'rename:Rename a worktree'
        'list:List all active Claude instances'
        'clean:Clean up invalid worktrees from state'
        'dir:Get the directory path of a worktree'
        'dashboard:Launch interactive dashboard for managing Claude sessions'
        'completions:Generate shell completions'
    )

    # Main command completion
    if (( CURRENT == 2 )); then
        _describe 'command' commands
        return
    fi

    # Subcommand argument completion
    case "${words[2]}" in
        open|dir|delete)
            if (( CURRENT == 3 )); then
                _xlaude_worktrees
            fi
            ;;
        rename)
            if (( CURRENT == 3 )); then
                _xlaude_worktrees
            elif (( CURRENT == 4 )); then
                _message "new name"
            fi
            ;;
        create|add)
            if (( CURRENT == 3 )); then
                _message "worktree name"
            fi
            ;;
        completions)
            if (( CURRENT == 3 )); then
                local -a shells
                shells=(bash zsh fish)
                _describe 'shell' shells
            fi
            ;;
    esac
}

_xlaude_worktrees() {
    local -a worktrees
    local IFS=$'\n'

    # Get detailed worktree information (sorted by repo, then by name)
    local worktree_data
    worktree_data=($(xlaude complete-worktrees --format=detailed 2>/dev/null))

    if [[ -n "$worktree_data" ]]; then
        for line in $worktree_data; do
            # Parse tab-separated values: name<TAB>repo<TAB>path<TAB>sessions
            local name=$(echo "$line" | cut -f1)
            local repo=$(echo "$line" | cut -f2)
            local sessions=$(echo "$line" | cut -f4)

            # Add worktree with clear repo marker and session info
            worktrees+=("$name:[$repo] $sessions")
        done

        # Use _describe for better presentation
        # -V flag preserves the order (no sorting)
        if (( ${#worktrees[@]} > 0 )); then
            _describe -V -t worktrees 'worktree' worktrees
        fi
    else
        # Fallback to simple completion
        local simple_worktrees
        simple_worktrees=($(xlaude complete-worktrees 2>/dev/null))
        if [[ -n "$simple_worktrees" ]]; then
            compadd -a simple_worktrees
        fi
    fi
}

_xlaude "$@"
