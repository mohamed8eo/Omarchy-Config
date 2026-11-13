# shellcheck shell=bash
# Step 20: system update, dev environments, Codex, and packages from packages.toml.

# Helper to run omarchy commands that need /dev/tty for password prompts
# In dry-run mode, don't use /dev/tty
_omarchy() {
  if _dry_run; then
    "$@"
  else
    "$@" </dev/tty
  fi
}

run_cmd 'Running omarchy update' _omarchy omarchy update || warn 'omarchy update failed; continuing.'

# Node goes first: the Codex launcher needs the mise-managed Node.
install_dev_env() {
  local name=$1 tool=$2
  if mise where "$tool" >/dev/null 2>&1; then
    printf 'Skipping %s (already installed via mise).\n' "$name"
  else
    run_cmd "Installing $name" _omarchy omarchy install dev-env "$name"
  fi
}
install_dev_env node node
install_dev_env go go
install_dev_env python python
if command -v rustc >/dev/null || mise where rust >/dev/null 2>&1; then
  printf 'Skipping rust (already installed).\n'
else
  run_cmd 'Installing rust' _omarchy omarchy install dev-env rust
fi

run_cmd 'Installing Codex' _omarchy omarchy install ai chatgpt

if ((${#PACMAN_PACKAGES[@]})); then
  run_cmd "Installing pacman packages: ${PACMAN_PACKAGES[*]}" _omarchy omarchy pkg add "${PACMAN_PACKAGES[@]}"
fi

if [[ " ${AUR_PACKAGES[*]:-} " == *" helium-browser-bin "* ]]; then
  # The AUR package verifies Helium's PGP signature, so its signing key must be known.
  run_cmd 'Importing Helium signing key' retry 3 gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys BE677C1989D35EAB2C5F26C9351601AD01D6378E || warn 'could not import Helium signing key; Helium install may fail.'
fi

if ((${#AUR_PACKAGES[@]})); then
  run_cmd "Installing AUR packages: ${AUR_PACKAGES[*]}" _omarchy omarchy pkg aur add "${AUR_PACKAGES[@]}"
fi

run_cmd 'Installing omarchy-fish' _omarchy omarchy pkg add omarchy-fish