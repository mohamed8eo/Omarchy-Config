# Omarchy Setup

Personal setup files and installer for my Omarchy machine.

## Install

Run as your normal user from an Omarchy session:

```bash
curl -fsSL https://raw.githubusercontent.com/mohamed8eo/Omarchy-Config/main/install.bash | bash
```

The small entrypoint clones the latest `main` branch into a temporary directory, then runs `setup.bash` with the full repository available. The temporary checkout is removed when the installer exits.

From a local checkout, run `./setup.bash`.

## What you see when it runs

The installer prints a banner, then runs numbered phases. Each phase announces what it is about to do:

```
==> [4/14] Packages and development tools
    Updates the system, installs Node.js, Go, Python and Rust, Codex, and the packages listed in packages.toml.
 [ INFO ] Running omarchy update...
 [  OK  ] System updated
 [ SKIP ] node is already installed (mise)
 [ WARN ] could not import the Helium signing key; the Helium install may fail.
```

| Tag | Meaning |
|---|---|
| `[ INFO ]` | something is starting or was backed up |
| `[  OK  ]` | a step finished |
| `[ SKIP ]` | nothing to do (already installed, or you chose to skip) |
| `[ NOTE ]` | a heads-up, such as a retry |
| `[ WARN ]` | a non-fatal problem; collected in the final summary |
| `[ERROR ]` | the setup stopped (see below) |

Before anything changes, the **plan** phase lists every phase, every file that will be replaced and the packages, and asks for confirmation. The list is generated from the phase files, so it always matches what the installer really does.

A failure prints a standard block and stops:

```
 [ERROR ] Setup stopped because a command failed.
          Phase     [4/14] Packages and development tools
          Where     20-packages.bash:40
          Command   omarchy pkg add ...
          Exit      1
          Backups   ~/.local/state/omarchy-setup/backups
          Log       ~/.local/state/omarchy-setup/logs/setup-<timestamp>.log
          Next      Fix the problem above, then re-run ./setup.bash.
```

Colors are used only on a terminal; set `NO_COLOR=1` to turn them off. A plain-text log of every phase, warning and error is written to `~/.local/state/omarchy-setup/logs/`.

## sudo password

Right after you confirm the plan, the installer asks for your sudo password **once** and keeps sudo's own credential cache alive in the background. Package installs, `chsh` and everything else that needs sudo then run without more prompts. The password is never read, stored or logged by the script, and the credential is forgotten again when the installer exits (only if the installer was the one that asked for it).

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
├── lib/
│   ├── ui.bash         # output: banner, phases, status lines
│   └── common.bash     # sudo, errors, retries, backups
└── steps/              # one file per phase, run in filename order
    ├── 00-checks.bash      preflight checks + packages.toml parsing
    ├── 10-plan.bash        plan preview and confirmation
    ├── 15-sudo.bash        ask for the sudo password once
    ├── 20-packages.bash    omarchy update, dev envs, Codex, packages
    ├── 30-shell.bash       Fish as login shell
    ├── 35-git.bash         Git setup + SSH key
    ├── 40-terminal.bash    Ghostty + default terminal
    ├── 45-browser.bash     Helium hardware acceleration fix + default browser
    ├── 50-configs.bash     theme, config/ files, wallpapers
    ├── 55-dev.bash         Neovim config + ~/personal repos
    ├── 56-cliamp.bash      cliamp Quran player setup
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

- **A phase:** add `steps/NN-name.bash` that starts with a metadata header. The header drives the progress line and the plan, so there is nothing else to register:

  ```bash
  # shellcheck shell=bash
  # PHASE: Short title
  # ABOUT: One line describing what the phase does.
  # PLAN: hide        (optional: leave it out of the plan list)
  ```

  Phases are sourced in filename order and can use the helpers `info`, `ok`, `skip`, `note`, `warn`, `die`, `retry`, `copy_file`, `backup_if_present` and `run_optional`.

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

- Runs `omarchy update` first. If it fails (for example a broken mirror), it warns and continues.
- Installs Node.js, Go, Python and Rust (`omarchy install dev-env`, skipping any already installed), Codex (`omarchy install ai chatgpt`), the packages in `packages.toml` and `omarchy-fish`.
- Changes the account login shell to Fish using the cached sudo credential. A failure is retried (3 attempts); if it still fails the setup continues and the summary shows the `chsh` command to run later.
- Sets up Git with `omarchy setup git`, then asks for an email (pre-filled from your Git config, or from `SSH_EMAIL` if set) and runs `ssh-keygen -t ed25519 -C "<email>"` to create `~/.ssh/id_ed25519`. An existing key is never overwritten, and leaving the email empty skips the key. The public key is printed so you can add it at <https://github.com/settings/ssh/new>.
- Installs Ghostty with `omarchy install terminal ghostty` and puts it first in `~/.config/xdg-terminals.list` so it is the default terminal (the old file is backed up).
- Installs Helium's hardware video acceleration fix from `docs/omarchy-chromium-hardware-acceleration-fix.md`, adapted for Helium (wrapper at `~/.local/bin/omarchy-launch-helium`, flags in `~/.config/helium-browser-flags.conf`, and a `helium-browser.desktop` override in `~/.local/share/applications/`), and sets Helium as the default browser. Verify at `chrome://gpu` (Video Decode should say Hardware accelerated).
- Applies the Catppuccin Omarchy theme and installs everything in `config/` into `~/.config/` (Hyprland, Ghostty, cliamp, Starship, tmux). Existing files are backed up under `~/.local/state/omarchy-setup/backups/<timestamp>/` before replacement. Ghostty's existing `~/.config/ghostty/config` is also kept as `~/.config/ghostty/config-bak` (an existing `config-bak` is never overwritten).
- Copies `wallpapers/` and sets the desktop background.
- Installs the Neovim config from [`mohamed8eo/nvim_config`](https://github.com/mohamed8eo/nvim_config): if `~/.config/nvim` exists it is moved to `~/.config/nvim-bak`, then the cloned config is copied to `~/.config/nvim`.
- Creates `~/personal` and clones [`ThePrimeagen/harpoon`](https://github.com/ThePrimeagen/harpoon) and [`ThePrimeagen/99`](https://github.com/ThePrimeagen/99) into it (skipping any that already exist).
- Sets up cliamp as a Quran player: optionally downloads the audio (about 2 GB, asks first, skipped automatically when `~/.Quran` already has audio), points the installed config at `~/.Quran`, creates the `Quran` playlist, overrides the desktop launcher to start it, and adds a Fish `cliamp` function.
- Removes these web app launchers if they exist: Google Contacts, Google Maps, Google Messages, Google Photos, HEY, X, Zoom, Basecamp (`omarchy webapp remove <name>`).
- Installs the Omarchy plugins `qylock-oma`, `omarchy-spotlight` and `island` (then runs `omarchy bar use guilhermerisu.island`). A failing plugin step is reported and skipped.
- Ends with a summary (backups, log file, shell status, warnings) and a Yes/No prompt to restart the PC.

## Error handling

- A failing core step stops the setup and prints the phase, `file:line` and exact command that failed; re-run after fixing it.
- Network operations (`git clone`, the Helium key import, the Quran download) are retried 3 times.
- Optional parts (update, Ghostty install, Helium fix, wallpaper, repos, cliamp, web apps, plugins) only produce warnings, which are listed in the final summary.
- The script checks for an internet connection first (`SKIP_NET_CHECK=1` skips the check).
- Temporary files and the sudo keep-alive are cleaned up on success, failure and Ctrl+C.
