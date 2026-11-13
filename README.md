# Omarchy Setup

Personal setup files and installer for my Omarchy machine.

## Install

Run as your normal user from an Omarchy session:

```bash
curl -fsSL https://raw.githubusercontent.com/mohamed8eo/Omarchy-Config/main/install.bash | bash
```

The small entrypoint clones the latest `main` branch into a temporary directory, then runs `setup.bash` with the full repository available. The temporary checkout is removed when the installer exits.

## Package manifest

Add package names to `packages.toml`:

```toml
pacman = ["example-pacman-package"]
aur = ["example-aur-package"]
```

The installer runs `omarchy update` first; if the update fails it prints a warning and continues. It then installs Node.js, Go, Python and Rust (`omarchy install dev-env`), Codex (`omarchy install ai chatgpt`), the listed packages and `omarchy-fish`. AUR installation requires Omarchy's AUR package workflow to be available.

## What it changes

- Shows a file-by-file preview and asks before making system changes.
- Runs `omarchy update` first. If it fails (for example a broken mirror), it warns and continues. Other failing steps still stop the setup, except Ghostty and the plugins, which are skipped.
- Applies the Catppuccin Omarchy theme and copies `images/` into `~/.config/omarchy/backgrounds/catppuccin/`.
- Backs up existing destination files under `~/.local/state/omarchy-setup/backups/<timestamp>/` before replacement.
- Copies same-named files from `hypr/` into `~/.config/hypr/`.
- Copies `starship.toml` to `~/.config/starship.toml` and `tmux.conf` to `~/.config/tmux/tmux.conf`.
- Installs the Neovim config from [`mohamed8eo/nvim_config`](https://github.com/mohamed8eo/nvim_config): if `~/.config/nvim` exists it is moved to `~/.config/nvim-bak`, then the cloned config is copied to `~/.config/nvim`.
- Creates `~/personal` and clones [`ThePrimeagen/harpoon`](https://github.com/ThePrimeagen/harpoon) and [`ThePrimeagen/99`](https://github.com/ThePrimeagen/99) into it (skipping any that already exist).
- Installs dev environments (Node.js, Go, Python, Rust) with `omarchy install dev-env`, skipping any already installed via mise.
- Installs Codex with `omarchy install ai chatgpt`.
- Installs `httpie`, `pnpm` (pacman) and `cliamp`, `claude-desktop` (AUR) from `packages.toml`.
- Installs Helium (`helium-browser-bin`, AUR), applies the hardware video acceleration fix from `omarchy-chromium-hardware-acceleration-fix.md` adapted for Helium (wrapper at `~/.local/bin/omarchy-launch-helium`, flags in `~/.config/helium-browser-flags.conf`, and a `helium-browser.desktop` override in `~/.local/share/applications/`), and sets Helium as the default browser (`xdg-settings`). Verify at `chrome://gpu` (Video Decode should say Hardware accelerated).
- Installs Ghostty with `omarchy install terminal ghostty` and puts it first in `~/.config/xdg-terminals.list` so it is the default terminal (the old file is backed up).
- Removes these web app launchers if they exist: Google Contacts, Google Maps, Google Messages, Google Photos, HEY, X, Zoom, Basecamp (`omarchy webapp remove <name>`). Missing ones are skipped.
- At the end, installs the Omarchy plugins `lock-designs`, `omarchy-spotlight`, `Omarchy-VoxType-OSD` (plus its setup script) and `island` (then runs `omarchy bar use guilhermerisu.island`). A failing plugin step is reported and skipped.
- Installs `omarchy-fish` and changes the account login shell to Fish.
