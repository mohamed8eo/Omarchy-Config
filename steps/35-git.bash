# shellcheck shell=bash
# PHASE: Git and SSH key
# ABOUT: Runs omarchy setup git, then asks for your email and creates an ed25519 SSH key. An existing key is never overwritten.

info 'Setting up Git (omarchy setup git)...'
if omarchy setup git </dev/tty; then
  ok 'Git configured'
else
  warn '"omarchy setup git" failed; run it manually later.'
fi

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_KEY_CREATED=0

# Ask for the key's email, then run: ssh-keygen -t ed25519 -C "<email>"
# An existing key is never overwritten. SSH_EMAIL can pre-fill the question; otherwise the
# email Git was just configured with is offered as the default. Leaving it empty skips the key.
create_ssh_key() {
  local email default attempt max_attempts=3
  if [[ -e $SSH_KEY || -L $SSH_KEY ]]; then
    skip "SSH key already exists, not overwriting: $SSH_KEY"
    return 0
  fi
  if ! command -v ssh-keygen >/dev/null 2>&1; then
    warn 'ssh-keygen not found; skipped SSH key creation.'
    return 1
  fi

  default=${SSH_EMAIL:-$(git config --global user.email 2>/dev/null || true)}
  info 'Creating an ed25519 SSH key...'
  email=''
  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    read -r -e -i "$default" -p 'Email for the SSH key (leave empty to skip): ' email </dev/tty || email=''
    if [[ -z $email ]]; then
      skip 'SSH key creation skipped'
      return 0
    fi
    if [[ $email =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]]; then
      break
    fi
    note 'That does not look like an email address. Please try again.'
    email=''
  done
  if [[ -z $email ]]; then
    warn 'no valid email entered; skipped SSH key creation.'
    return 1
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  # -f is given so ssh-keygen doesn't ask for the file name (it is the default path anyway);
  # it still asks for an optional passphrase.
  if ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" </dev/tty; then
    SSH_KEY_CREATED=1
    ok "SSH key created: $SSH_KEY"
    printf '\n    Public key (add it at https://github.com/settings/ssh/new):\n\n'
    printf '    %s\n\n' "$(cat "$SSH_KEY.pub")"
  else
    warn "ssh-keygen failed; run it later: ssh-keygen -t ed25519 -C \"$email\""
    return 1
  fi
}
create_ssh_key || true
