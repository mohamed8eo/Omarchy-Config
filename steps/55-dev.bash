# shellcheck shell=bash
# Step 55: Neovim config from GitHub and personal repos.

# Neovim config from mohamed8eo/nvim_config.
# Backs up the current ~/.config/nvim to ~/.config/nvim-bak, clones the repo, and installs it.
printf '\nInstalling Neovim config...\n'
if command -v git >/dev/null 2>&1; then
  NVIM_CONFIG_DIR="$HOME/.config/nvim"
  NVIM_BACKUP_DIR="$HOME/.config/nvim-bak"
  NVIM_TMP_DIR=$(mktemp -d)
  TMP_PATHS+=("$NVIM_TMP_DIR")
  if retry 3 git clone --depth 1 https://github.com/mohamed8eo/nvim_config.git "$NVIM_TMP_DIR/nvim" </dev/tty; then
    if [[ -e $NVIM_CONFIG_DIR || -L $NVIM_CONFIG_DIR ]]; then
      rm -rf -- "$NVIM_BACKUP_DIR"
      mv -- "$NVIM_CONFIG_DIR" "$NVIM_BACKUP_DIR"
      printf 'Backed up %s to %s\n' "$NVIM_CONFIG_DIR" "$NVIM_BACKUP_DIR"
    fi
    mkdir -p "$(dirname -- "$NVIM_CONFIG_DIR")"
    cp -a -- "$NVIM_TMP_DIR/nvim" "$NVIM_CONFIG_DIR"
    rm -rf -- "$NVIM_CONFIG_DIR/.git"
    printf 'Installed Neovim config at %s\n' "$NVIM_CONFIG_DIR"
  else
    warn 'failed to clone mohamed8eo/nvim_config; skipped the Neovim config install.'
  fi
  rm -rf -- "$NVIM_TMP_DIR"
else
  warn 'git not found; skipped the Neovim config install.'
fi

# Personal repos.
printf '\nSetting up ~/personal repos...\n'
if command -v git >/dev/null 2>&1; then
  PERSONAL_DIR="$HOME/personal"
  mkdir -p "$PERSONAL_DIR"
  for repo in harpoon 99; do
    target="$PERSONAL_DIR/$repo"
    if [[ -e $target ]]; then
      printf 'Personal repo already present, skipping: %s\n' "$target"
    elif retry 3 git clone --depth 1 "https://github.com/ThePrimeagen/$repo.git" "$target" </dev/tty; then
      printf 'Cloned %s\n' "$target"
    else
      warn "failed to clone ThePrimeagen/$repo; continuing."
    fi
  done
else
  warn 'git not found; skipped the ~/personal repos.'
fi
