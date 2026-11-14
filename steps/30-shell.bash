# shellcheck shell=bash
# PHASE: Login shell
# ABOUT: Makes Fish your login shell. Uses the cached sudo credential, so no extra password is needed; a failure is retried and never stops the setup.

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
    skip "Login shell is already $fish_path"
    LOGIN_SHELL_OK=1
    return 0
  fi
  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    info "Changing login shell to $fish_path (attempt $attempt of $max_attempts)..."
    # sudo uses the cached credential, so chsh does not ask for your password again.
    if sudo chsh -s "$fish_path" "$USER" </dev/tty; then
      ok "Login shell changed to $fish_path (active after your next login)"
      LOGIN_SHELL_OK=1
      return 0
    fi
    if ((attempt < max_attempts)); then
      note 'Could not change the login shell (wrong password?). Please try again.'
    fi
  done
  warn "could not change the login shell after $max_attempts attempts; run later: chsh -s $fish_path"
  return 1
}
set_login_shell || true
