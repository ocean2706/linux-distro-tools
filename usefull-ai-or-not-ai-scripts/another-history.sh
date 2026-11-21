#####cat /etc/profile.d/99-history-timestamps.sh
#!/bin/bash
# Global history configuration: timestamps + persistence even on abrupt disconnects
# --- History behavior (put shopt early) ---
shopt -s histappend          # append to history, don't overwrite on shell close
shopt -u checkwinsize        # optional: update $LINES/$COLUMNS reliably

# --- History size / de-dup ---
export HISTSIZE=10000
export HISTFILESIZE=10000
export IGNORECASE=yes
export IGNORE_DUPES=no
# 1) Show a timestamp with each history entry (epoch seconds, UTC)
export HISTTIMEFORMAT="%Y-%m-%dT%H:%M:%SZ "

# 2) Keep more history than the default and don't override duplicates
export HISTSIZE=10000
export HISTFILESIZE=10000
export IGNORECASE=yes
export IGNORE_DUPES=no

# 3) Force history to be written to disk after EVERY command,
#    so it survives an abrupt session drop (no clean EXIT/SIGHUP).
#    PROMPT_COMMAND runs before each new prompt, so this is frequent.
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
