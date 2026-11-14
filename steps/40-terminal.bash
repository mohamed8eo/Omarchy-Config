# shellcheck shell=bash
# PHASE: Terminal
# ABOUT: Installs Ghostty and makes it the default terminal. Its config (config/ghostty/config) is applied in the configuration phase.

# Omarchy launches terminals through xdg-terminal-exec, which uses the first entry of
# ~/.config/xdg-terminals.list.
info 'Installing Ghostty...'
if omarchy install terminal ghostty </dev/tty; then
  ok 'Ghostty installed'
else
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
ok "Default terminal: Ghostty ($XDG_TERMINALS)"
