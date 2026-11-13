# shellcheck shell=bash
# Step 20: system update, dev environments, Codex, and packages from packages.toml.

printf '\nRunning omarchy update...\n'
if ! omarchy update </dev/tty; then
  warn 'omarchy update failed; skipped it and continued.'
fi

# Node goes first: the Codex launcher needs the mise-managed Node.
install_dev_env() {
  local name=$1 tool=$2
  if mise where "$tool" >/dev/null 2>&1; then
    printf 'Skipping %s (already installed via mise).\n' "$name"
  else
    printf '\nInstalling %s...\n' "$name"
    omarchy install dev-env "$name" </dev/tty
  fi
}
install_dev_env node node
install_dev_env go go
install_dev_env python python
if command -v rustc >/dev/null || mise where rust >/dev/null 2>&1; then
  printf 'Skipping rust (already installed).\n'
else
  printf '\nInstalling rust...\n'
  omarchy install dev-env rust </dev/tty
fi

printf '\nInstalling Codex...\n'
omarchy install ai chatgpt </dev/tty

if ((${#PACMAN_PACKAGES[@]})); then omarchy pkg add "${PACMAN_PACKAGES[@]}" </dev/tty; fi
if [[ " ${AUR_PACKAGES[*]:-} " == *" helium-browser-bin "* ]]; then
  # The AUR package verifies Helium's PGP signature, so its signing key must be known.
  printf '\nImporting Helium signing key...\n'
  if ! retry 3 gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys BE677C1989D35EAB2C5F26C9351601AD01D6378E </dev/tty; then
    warn 'could not import the Helium signing key; the Helium install may fail.'
  fi
fi
if ((${#AUR_PACKAGES[@]})); then omarchy pkg aur add "${AUR_PACKAGES[@]}" </dev/tty; fi
omarchy pkg add omarchy-fish </dev/tty
