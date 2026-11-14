# shellcheck shell=bash
# PHASE: Neovim config and personal repos
# ABOUT: Installs your Neovim config from mohamed8eo/nvim_config (the old one is kept as nvim-bak) and clones ThePrimeagen/harpoon and ThePrimeagen/99 into ~/personal.

# Neovim config from mohamed8eo/nvim_config.
# Backs up the current ~/.config/nvim to ~/.config/nvim-bak, clones the repo, and installs it.
if command -v git >/dev/null 2>&1; then
  info 'Installing the Neovim config...'
  NVIM_CONFIG_DIR="$HOME/.config/nvim"
  NVIM_BACKUP_DIR="$HOME/.config/nvim-bak"
  NVIM_TMP_DIR=$(mktemp -d)
  TMP_PATHS+=("$NVIM_TMP_DIR")
  if retry 3 git clone --depth 1 https://github.com/mohamed8eo/nvim_config.git "$NVIM_TMP_DIR/nvim" </dev/tty; then
    if [[ -e $NVIM_CONFIG_DIR || -L $NVIM_CONFIG_DIR ]]; then
      rm -rf -- "$NVIM_BACKUP_DIR"
      mv -- "$NVIM_CONFIG_DIR" "$NVIM_BACKUP_DIR"
      info "Backed up $NVIM_CONFIG_DIR to $NVIM_BACKUP_DIR"
    fi
    mkdir -p "$(dirname -- "$NVIM_CONFIG_DIR")"
    cp -a -- "$NVIM_TMP_DIR/nvim" "$NVIM_CONFIG_DIR"
    rm -rf -- "$NVIM_CONFIG_DIR/.git"
    ok "Installed Neovim config at $NVIM_CONFIG_DIR"
  else
    warn 'failed to clone mohamed8eo/nvim_config; skipped the Neovim config install.'
  fi
  rm -rf -- "$NVIM_TMP_DIR"
else
  warn 'git not found; skipped the Neovim config install.'
fi

# Personal repos.
if command -v git >/dev/null 2>&1; then
  info 'Setting up ~/personal repos...'
  PERSONAL_DIR="$HOME/personal"
  mkdir -p "$PERSONAL_DIR"
  for repo in harpoon 99; do
    target="$PERSONAL_DIR/$repo"
    if [[ -e $target ]]; then
      skip "Personal repo already present: $target"
    elif retry 3 git clone --depth 1 "https://github.com/ThePrimeagen/$repo.git" "$target" </dev/tty; then
      ok "Cloned $target"
    else
      warn "failed to clone ThePrimeagen/$repo; continuing."
    fi
  done
else
  warn 'git not found; skipped the ~/personal repos.'
fi
