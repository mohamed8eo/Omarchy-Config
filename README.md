# Omarchy Setup

Personal setup files and installer for my Omarchy machine.

## Install

Run as your normal user from an Omarchy session:

```bash
curl -fsSL https://raw.githubusercontent.com/mohamed8eo/Omarchy-Config/main/install.bash | bash
```

The small entrypoint clones the latest `main` branch into a temporary directory, then runs `setup.bash` with the full repository available. The temporary checkout is removed when the installer exits.

From a local checkout, run `./setup.bash`.

## Repository layout

```
.
├── install.bash        # curl entrypoint (clones the repo, runs setup.bash)
├── setup.bash          # orchestrator: loads lib/ and runs steps/ in order
├── packages.toml       # pacman / AUR package manifest
├── config/             # mirrors ~/.config, every file here gets installed
│   ├── ghostty/config
│   ├── hypr/…
│   ├── cliamp/config.toml
│   ├── starship.toml
│   └── tmux/tmux.conf
├── wallpapers/         # copied to ~/.config/omarchy/backgrounds/catppuccin/
├── docs/               # notes (Helium/Chromium hardware acceleration fix)
├── lib/common.bash     # shared helpers: errors, retries, backups
└── steps/              # one file per setup step, run in filename order
    ├── 00-checks.bash      preflight checks + packages.toml parsing
    ├── 10-plan.bash        preview and confirmation
    ├── 20-packages.bash    omarchy update, dev envs, Codex, packages
    ├── 30-shell.bash       Fish as login shell (wrong password is retried)
    ├── 35-git.bash         Git setup + SSH key
    ├── 40-terminal.bash    Ghostty + default terminal
    ├── 45-browser.bash     Helium hardware acceleration fix + default browser
    ├── 50-configs.bash     theme, config/ files, wallpapers
    ├── 55-dev.bash         Neovim config + ~/personal repos
    ├── 60-webapps.bash     remove unwanted web app launchers
    ├── 70-plugins.bash     Omarchy plugins
    └── 90-finish.bash      summary + restart prompt
```

### Adding things

- **A config file:** put it under `config/` using its path relative to `~/.config`, for example `config/foo/bar.conf` is installed to `~/.config/foo/bar.conf`. It is previewed, backed up and installed automatically, with no script edit.
- **A package:** add it to `packages.toml`:

  ```toml
  pacman = ["example-pacman-package"]
  aur = ["example-aur-package"]
  ```

- **A setup step:** add `steps/NN-name.bash`. Steps are sourced in filename order and can use the helpers in `lib/common.bash` (`warn`, `retry`, `copy_file`, `backup_if_present`, `run_optional`).

## Desktop background

The installer copies every file from `wallpapers/` into `~/.config/omarchy/backgrounds/catppuccin/` and then sets `139396752_p0.jpg` as the desktop background using `omarchy theme bg set`. To use a different image, export `WALLPAPER_IMAGE` with its filename before running the installer:

```bash
export WALLPAPER_IMAGE=tree.jpg
curl -fsSL https://raw.githubusercontent.com/mohamed8eo/Omarchy-Config/main/install.bash | bash
```

When running from a local checkout, use `WALLPAPER_IMAGE=tree.jpg ./setup.bash`. You can change it later with:

```bash
omarchy theme bg set ~/.config/omarchy/backgrounds/catppuccin/tree.jpg
```

## What it changes

- Shows a file-by-file preview and asks before making system changes.
- Runs `omarchy update` first. If it fails (for example a broken mirror), it warns and continues.
- Installs Node.js, Go, Python and Rust (`omarchy install dev-env`, skipping any already installed), Codex (`omarchy install ai chatgpt`), the packages in `packages.toml` (`httpie`, `pnpm`, `ripgrep`, `cliamp`, `claude-desktop`, `helium-browser-bin`) and `omarchy-fish`.
- Changes the account login shell to Fish. A wrong password is retried (3 attempts); if it still fails the setup continues and the summary shows the `chsh` command to run later.
- Sets up Git with `omarchy setup git`, then asks for an email (pre-filled from your Git config, or from `SSH_EMAIL` if set) and runs `ssh-keygen -t ed25519 -C "<email>"` to create `~/.ssh/id_ed25519`. An existing key is never overwritten, and leaving the email empty skips the key. The public key is printed so you can add it at <https://github.com/settings/ssh/new>.
- Installs Ghostty with `omarchy install terminal ghostty` and puts it first in `~/.config/xdg-terminals.list` so it is the default terminal (the old file is backed up).
- Installs Helium's hardware video acceleration fix from `docs/omarchy-chromium-hardware-acceleration-fix.md`, adapted for Helium (wrapper at `~/.local/bin/omarchy-launch-helium`, flags in `~/.config/helium-browser-flags.conf`, and a `helium-browser.desktop` override in `~/.local/share/applications/`), and sets Helium as the default browser. Verify at `chrome://gpu` (Video Decode should say Hardware accelerated).
- Applies the Catppuccin Omarchy theme and installs everything in `config/` into `~/.config/` (Hyprland, Ghostty, cliamp, Starship, tmux). Existing files are backed up under `~/.local/state/omarchy-setup/backups/<timestamp>/` before replacement. Ghostty's existing `~/.config/ghostty/config` is also kept as `~/.config/ghostty/config-bak` (an existing `config-bak` is never overwritten).
- Copies `wallpapers/` and sets the desktop background.
- Installs the Neovim config from [`mohamed8eo/nvim_config`](https://github.com/mohamed8eo/nvim_config): if `~/.config/nvim` exists it is moved to `~/.config/nvim-bak`, then the cloned config is copied to `~/.config/nvim`.
- Creates `~/personal` and clones [`ThePrimeagen/harpoon`](https://github.com/ThePrimeagen/harpoon) and [`ThePrimeagen/99`](https://github.com/ThePrimeagen/99) into it (skipping any that already exist).
- Removes these web app launchers if they exist: Google Contacts, Google Maps, Google Messages, Google Photos, HEY, X, Zoom, Basecamp (`omarchy webapp remove <name>`).
- Installs the Omarchy plugins `qylock-oma`, `omarchy-spotlight` and `island` (then runs `omarchy bar use guilhermerisu.island`). A failing plugin step is reported and skipped.
- Ends with a summary (backups, shell status, warnings) and a Yes/No prompt to restart the PC.

## Error handling

- A failing step stops the setup and prints the step, file:line and exact command that failed; re-run after fixing it.
- Network operations (`git clone`, the Helium key import) are retried 3 times.
- Optional parts (update, Ghostty install, Helium fix, wallpaper, repos, web apps, plugins) only produce warnings, which are listed in the final summary.
- The script checks for an internet connection first (`SKIP_NET_CHECK=1` skips the check).
- Temporary files are cleaned up on success, failure and Ctrl+C.
