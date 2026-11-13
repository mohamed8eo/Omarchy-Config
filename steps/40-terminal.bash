# shellcheck shell=bash
# Step 40: install Ghostty and make it the default terminal.
# Its config lives in config/ghostty/config and is installed by step 50.

# Omarchy launches terminals through xdg-terminal-exec, which uses the first entry of
# ~/.config/xdg-terminals.list.
printf '\nInstalling Ghostty...\n'
if ! omarchy install terminal ghostty </dev/tty; then
  warn '"omarchy install terminal ghostty" failed; continuing.'
fi
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
GHOSTTY_DESKTOP=com.mitchellh.ghostty.desktop
if [[ $(head -n 1 "$XDG_TERMINALS" 2>/dev/null || true) != "$GHOSTTY_DESKTOP" ]]; then
  backup_if_present "$XDG_TERMINALS" xdg-terminals.list
  mkdir -p "$(dirname -- "$XDG_TERMINALS")"
  XDG_TMP=$(mktemp)
  TMP_PATHS+=("$XDG_TMP")
  { printf '%s\n' "$GHOSTTY_DESKTOP"; grep -vFx -- "$GHOSTTY_DESKTOP" "$XDG_TERMINALS" 2>/dev/null || true; } > "$XDG_TMP"
  mv -- "$XDG_TMP" "$XDG_TERMINALS"
fi
printf 'Default terminal: Ghostty (%s)\n' "$XDG_TERMINALS"
