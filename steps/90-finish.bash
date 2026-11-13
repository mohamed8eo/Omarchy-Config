# shellcheck shell=bash
# Step 90: summary and restart prompt.

printf '\n================ Setup summary ================\n'
printf 'Backups of replaced files: %s\n' "$BACKUP_DIR"
for sibling_file in "${SIBLING_BACKUP_FILES[@]}"; do
  if [[ -e $HOME/.config/$sibling_file-bak ]]; then
    printf 'Original kept at:          %s\n' "$HOME/.config/$sibling_file-bak"
  fi
done
if ((LOGIN_SHELL_OK)); then
  printf 'Fish is your login shell (takes effect on your next login).\n'
else
  printf 'Login shell was NOT changed; run later: chsh -s "$(command -v fish)"\n' >&2
fi
if ((${#FAILED_PLUGINS[@]})); then
  printf 'Plugin steps that failed and were skipped: %s\n' "${FAILED_PLUGINS[*]}" >&2
fi
if ((${#WARNINGS[@]})); then
  printf '\n%d warning(s) during setup:\n' "${#WARNINGS[@]}" >&2
  for w in "${WARNINGS[@]}"; do printf '  - %s\n' "$w" >&2; done
elif ((${#FAILED_PLUGINS[@]} == 0)); then
  printf 'Everything finished without errors.\n'
fi
printf '===============================================\n\n'

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
  printf 'Restarting in 5 seconds (press Ctrl+C to cancel)...\n'
  sleep 5
  if ! systemctl reboot; then
    printf 'Could not restart automatically; please restart the PC manually.\n' >&2
  fi
else
  printf 'Not restarting. Restart or log out and back in later to apply all changes.\n'
fi
