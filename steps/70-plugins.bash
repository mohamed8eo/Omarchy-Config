# shellcheck shell=bash
# Step 70: Omarchy plugins. A failing plugin is reported and skipped; it never stops the setup.

run_cmd 'Installing Omarchy plugins' true

# QyLock - Themed lock screen and live backgrounds
run_optional 'Lock Designs (plugin add)' omarchy plugin add https://github.com/SmoothPixels/lock-designs.git --enable
if ! _dry_run && run_optional 'Lock Designs (shell explore)' omarchy-shell lock explore; then
  true
fi

run_optional 'omarchy-spotlight' omarchy plugin add https://github.com/maajix/omarchy-spotlight.git --enable

if run_optional 'island plugin (add)' omarchy plugin add https://github.com/mohamed8eo/island.git; then
  run_optional 'island bar' omarchy bar use guilhermerisu.island
fi

# Restart Omarchy shell to load QyLock and other plugins
run_cmd 'Restarting Omarchy shell' omarchy restart shell || warn 'omarchy restart shell failed; plugins will load after a reboot.'