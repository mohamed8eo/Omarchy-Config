# shellcheck shell=bash
# PHASE: Summary
# ABOUT: Shows the result of the setup, any warnings, and offers to restart the PC.
# PLAN: hide

elapsed=$(format_duration "$SECONDS")
printf '\n'
if ((${#WARNINGS[@]} == 0 && ${#FAILED_PLUGINS[@]} == 0)); then
  ok "Setup completed successfully in $elapsed."
else
  note "Setup finished in $elapsed with ${#WARNINGS[@]} warning(s); details below."
fi
printf '\n'
kv 'Backups' "$BACKUP_DIR"
kv 'Log file' "$LOG_FILE"
for sibling_file in "${SIBLING_BACKUP_FILES[@]}"; do
  if [[ -e $HOME/.config/$sibling_file-bak ]]; then
    kv 'Original kept' "$HOME/.config/$sibling_file-bak"
  fi
done
if ((SSH_KEY_CREATED)); then
  kv 'SSH public key' "$SSH_KEY.pub (add it at https://github.com/settings/ssh/new)"
fi
if ((LOGIN_SHELL_OK)); then
  kv 'Login shell' 'Fish (active after your next login)'
else
  kv 'Login shell' 'NOT changed; run later: chsh -s "$(command -v fish)"'
fi
if ((${#FAILED_PLUGINS[@]})); then
  kv 'Skipped plugins' "${FAILED_PLUGINS[*]}"
fi
if ((${#WARNINGS[@]})); then
  printf '\n    %sWarnings (%d):%s\n' "$C_YELLOW" "${#WARNINGS[@]}" "$C_RESET"
  for warning_text in "${WARNINGS[@]}"; do
    printf '      - %s\n' "$warning_text"
  done
fi
printf '\n'

# Restart prompt: a Yes/No button when gum (shipped with Omarchy) is available,
# otherwise a plain y/N question.
ask_restart() {
  local reply rc
  if command -v gum >/dev/null 2>&1; then
    rc=0
    gum confirm --default=false 'Restart the PC now to apply everything?' </dev/tty || rc=$?
    case $rc in
      0) return 0 ;;
      1 | 130) return 1 ;;
    esac
  fi
  read -r -p 'Restart the PC now to apply everything? [y/N] ' reply </dev/tty || return 1
  [[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

if ask_restart; then
  info 'Restarting in 5 seconds (press Ctrl+C to cancel)...'
  sleep 5
  if ! systemctl reboot; then
    warn 'Could not restart automatically; please restart the PC manually.'
  fi
else
  info 'Not restarting. Restart or log out and back in later to apply all changes.'
fi
