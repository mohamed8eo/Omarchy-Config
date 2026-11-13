# shellcheck shell=bash
# Step 70: Omarchy plugins. A failing plugin is reported and skipped; it never stops the setup.

printf '\nInstalling Omarchy plugins...\n'

# QyLock - Themed lock screen and live backgrounds
if run_optional 'Lock Designs' omarchy plugin add https://github.com/SmoothPixels/lock-designs.git --enable; then
  run_optional 'Lock Designs' omarchy-shell lock explore || true
fi

run_optional 'omarchy-spotlight' omarchy plugin add https://github.com/maajix/omarchy-spotlight.git --enable || true

if run_optional 'island plugin' omarchy plugin add https://github.com/mohamed8eo/island.git; then
  run_optional 'island bar' omarchy bar use guilhermerisu.island || true
fi

# Restart Omarchy shell to load QyLock and other plugins
if ! omarchy restart shell; then
  warn 'omarchy restart shell failed; the plugins will load after a reboot.'
fi
