# shellcheck shell=bash
# Step 40: install Ghostty and make it the default terminal.
# Its config lives in config/ghostty/config and is installed by step 50.

# Omarchy launches terminals through xdg-terminal-exec, which uses the first entry of
# ~/.config/xdg-terminals.list.
run_cmd 'Installing Ghostty' _omarchy omarchy install terminal ghostty || warn '"omarchy install terminal ghostty" failed; continuing.'

XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
GHOSTTY_DESKTOP=com.mitchellh.ghostty.desktop

if [[ $(head -n 1 "$XDG_TERMINALS" 2>/dev/null || true) != "$GHOSTTY_DESKTOP" ]]; then
  backup_if_present "$XDG_TERMINALS" xdg-terminals.list
  run_cmd "Setting Ghostty as default terminal in $XDG_TERMINALS" mkdir -p "$(dirname -- "$XDG_TERMINALS")"
  if ! _dry_run; then
    XDG_TMP=$(mktemp)
    TMP_PATHS+=("$XDG_TMP")
    { printf '%s\n' "$GHOSTTY_DESKTOP"; grep -vFx -- "$GHOSTTY_DESKTOP" "$XDG_TERMINALS" 2>/dev/null || true; } > "$XDG_TMP"
    mv -- "$XDG_TMP" "$XDG_TERMINALS"
  fi
fi
printf 'Default terminal: Ghostty (%s)\n' "$XDG_TERMINALS"