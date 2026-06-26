#!/bin/bash
# Helper script to display git diff stats (+lines -lines) or a dot (●) if dirty with no line changes.
# Exits silently if clean or not a git repository.

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Get lines added/deleted across staged & unstaged changes (relative to HEAD)
diff_stats=$(git diff HEAD --numstat 2>/dev/null | awk '{add += $1; del += $2} END {if (add > 0 || del > 0) print "+" add " -" del}')

if [ -n "$diff_stats" ]; then
    echo "$diff_stats"
else
    # If no line additions/deletions, check if there are any other modifications (e.g. untracked files, empty file deletion)
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "●"
    fi
fi
