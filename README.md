# Omarchy Setup

Personal setup files and installer for my Omarchy machine.

## Install

Run as your normal user from an Omarchy session:

```bash
curl -fsSL https://raw.githubusercontent.com/mohamed8eo/omarchy-setup/main/install.bash | bash
```

The small entrypoint clones the latest `main` branch into a temporary directory, then runs `setup.bash` with the full repository available. The temporary checkout is removed when the installer exits.

## Package manifest

Add package names to `packages.toml`:

```toml
pacman = ["example-pacman-package"]
aur = ["example-aur-package"]
```

The installer runs `omarchy update` first, then installs Node.js, Go, Python and Rust (`omarchy install dev-env`), Codex (`omarchy install ai chatgpt`), the listed packages and `omarchy-fish`. AUR installation requires Omarchy's AUR package workflow to be available.

## What it changes

- Shows a file-by-file preview and asks before making system changes.
- Runs `omarchy update` first, then stops if any operation fails.
- Applies the Catppuccin Omarchy theme and copies `images/` into `~/.config/omarchy/backgrounds/catppuccin/`.
- Backs up existing destination files under `~/.local/state/omarchy-setup/backups/<timestamp>/` before replacement.
- Copies same-named files from `hypr/` into `~/.config/hypr/`.
- Copies `starship.toml` to `~/.config/starship.toml` and `tmux.conf` to `~/.config/tmux/tmux.conf`.
- Installs dev environments (Node.js, Go, Python, Rust) with `omarchy install dev-env`, skipping any already installed via mise.
- Installs Codex with `omarchy install ai chatgpt`.
- Installs `httpie`, `pnpm` (pacman) and `cliamp`, `claude-desktop` (AUR) from `packages.toml`.
- Installs `omarchy-fish` and changes the account login shell to Fish.
