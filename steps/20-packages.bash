# shellcheck shell=bash
# PHASE: Packages and development tools
# ABOUT: Updates the system, installs Node.js, Go, Python and Rust, Codex, and the packages listed in packages.toml (plus omarchy-fish).

info 'Running omarchy update...'
if omarchy update </dev/tty; then
  ok 'System updated'
else
  warn 'omarchy update failed; skipped it and continued.'
fi

# Node goes first: the Codex launcher needs the mise-managed Node.
install_dev_env() {
  local name=$1 tool=$2
  if mise where "$tool" >/dev/null 2>&1; then
    skip "$name is already installed (mise)"
  else
    info "Installing $name..."
    omarchy install dev-env "$name" </dev/tty
    ok "$name installed"
  fi
}
install_dev_env node node
install_dev_env go go
install_dev_env python python
if command -v rustc >/dev/null || mise where rust >/dev/null 2>&1; then
  skip 'rust is already installed'
else
  info 'Installing rust...'
  omarchy install dev-env rust </dev/tty
  ok 'rust installed'
fi

info 'Installing Codex...'
omarchy install ai chatgpt </dev/tty
ok 'Codex installed'

if ((${#PACMAN_PACKAGES[@]})); then
  info "Installing ${#PACMAN_PACKAGES[@]} pacman package(s): ${PACMAN_PACKAGES[*]}"
  omarchy pkg add "${PACMAN_PACKAGES[@]}" </dev/tty
  ok 'Pacman packages installed'
fi
if [[ " ${AUR_PACKAGES[*]:-} " == *" helium-browser-bin "* ]]; then
  # The AUR package verifies Helium's PGP signature, so its signing key must be known.
  info 'Importing the Helium signing key...'
  if retry 3 gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys BE677C1989D35EAB2C5F26C9351601AD01D6378E </dev/tty; then
    ok 'Helium signing key imported'
  else
    warn 'could not import the Helium signing key; the Helium install may fail.'
  fi
fi
if ((${#AUR_PACKAGES[@]})); then
  info "Installing ${#AUR_PACKAGES[@]} AUR package(s): ${AUR_PACKAGES[*]}"
  omarchy pkg aur add "${AUR_PACKAGES[@]}" </dev/tty
  ok 'AUR packages installed'
fi
info 'Installing omarchy-fish...'
omarchy pkg add omarchy-fish </dev/tty
ok 'omarchy-fish installed'
