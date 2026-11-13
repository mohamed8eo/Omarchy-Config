# shellcheck shell=bash
# Step 30: make Fish the login shell.
# A wrong password is retried, and a failure here never stops the rest of the setup
# (the manual command is shown in the summary).

set_login_shell() {
  local fish_path current_shell attempt max_attempts=3
  if ! fish_path=$(command -v fish); then
    warn 'Fish was not found after installing omarchy-fish; login shell not changed.'
    return 1
  fi
  fish_path=$(realpath -- "$fish_path")
  if ! grep -Fxq "$fish_path" /etc/shells; then
    warn "$fish_path is not in /etc/shells; add it, then run: chsh -s $fish_path"
    return 1
  fi
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $current_shell == "$fish_path" ]]; then
    printf 'Login shell is already %s.\n' "$fish_path"
    LOGIN_SHELL_OK=1
    return 0
  fi
  run_cmd "Changing login shell to $fish_path" true
  if _dry_run; then
    LOGIN_SHELL_OK=1
    return 0
  fi
  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    printf 'Attempt %d/%d...\n' "$attempt" "$max_attempts"
    if chsh -s "$fish_path" "$USER" </dev/tty; then
      printf 'Login shell changed to %s.\n' "$fish_path"
      LOGIN_SHELL_OK=1
      return 0
    fi
    if ((attempt < max_attempts)); then
      printf 'Wrong password or chsh failed. Please try again.\n' >&2
    fi
  done
  warn "could not change the login shell after $max_attempts attempts; run later: chsh -s $fish_path"
  return 1
}
set_login_shell || true