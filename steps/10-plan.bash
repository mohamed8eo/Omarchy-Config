# shellcheck shell=bash
# Step 10: show what is about to happen and ask for confirmation.

printf 'Plan:\n'
printf '  Run omarchy update first (skipped with a warning if it fails)\n'
printf '  Install dev environments: Node.js, Go, Python, Rust (omarchy install dev-env)\n'
printf '  Install Codex (omarchy install ai chatgpt)\n'
printf '  Install packages listed in packages.toml and omarchy-fish\n'
printf '  Set Fish as this user’s login shell (wrong password is retried)\n'
printf '  Set up Git (omarchy setup git) and create an ed25519 SSH key (asks for the email; an existing key is never overwritten)\n'
printf '  Install Ghostty (omarchy install terminal ghostty) and make it the default terminal\n'
printf '  Apply the Helium hardware video acceleration fix (launcher wrapper, flags, desktop entry) and set Helium as the default browser\n'
printf '  Set the Catppuccin theme and install everything under config/ into ~/.config\n'
printf '  Copy wallpapers/ and set the desktop background to wallpapers/%s\n' "$WALLPAPER_IMAGE"
printf '  Install Neovim config from mohamed8eo/nvim_config (backs up ~/.config/nvim to ~/.config/nvim-bak)\n'
printf '  Create ~/personal and clone ThePrimeagen/harpoon and ThePrimeagen/99 into it\n'
printf '  Remove these web app launchers if present: Google Contacts, Google Maps, Google Messages, Google Photos, HEY, X, Zoom, Basecamp\n'
printf '  Install Omarchy plugins: qylock-oma, omarchy-spotlight, island (and switch the bar to island)\n'
printf '  Offer to restart the PC when everything is finished\n'
printf '  Replace these files (existing targets are backed up first; Ghostty’s config also goes to config-bak):\n'
find "$REPO_DIR/config" -type f -printf '    ~/.config/%P\n' | sort
find "$REPO_DIR/wallpapers" -maxdepth 1 -type f -printf '    ~/.config/omarchy/backgrounds/catppuccin/%f\n' | sort
printf '  Pacman: %s\n' "${PACMAN_PACKAGES[*]:-(none listed)}"
printf '  AUR:    %s\n' "${AUR_PACKAGES[*]:-(none listed)}"

if _dry_run; then
  printf '[DRY-RUN] Would prompt for confirmation. Skipping.\n'
else
  read -r -p 'Continue? [y/N] ' answer </dev/tty
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]] || { printf 'Cancelled.\n'; exit 0; }
fi
