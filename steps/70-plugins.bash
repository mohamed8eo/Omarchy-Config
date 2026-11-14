# shellcheck shell=bash
# PHASE: Omarchy plugins
# ABOUT: Installs the qylock-oma, omarchy-spotlight and island plugins and switches the bar to island. A failing plugin is reported and skipped.

# QyLock - Themed lock screen and live backgrounds
if run_optional 'Installing qylock-oma' omarchy plugin add https://github.com/mjtiempo/qylock-oma.git --enable --yes; then
  run_optional 'Syncing QyLock themes' omarchy-shell mark.lock-themes sync || true
fi

run_optional 'Installing omarchy-spotlight' omarchy plugin add https://github.com/maajix/omarchy-spotlight.git --enable || true

if run_optional 'Installing the island plugin' omarchy plugin add https://github.com/mohamed8eo/island.git; then
  run_optional 'Switching the bar to island' omarchy bar use guilhermerisu.island || true
fi

# Restart Omarchy shell to load QyLock and other plugins
info 'Restarting the Omarchy shell...'
if omarchy restart shell; then
  ok 'Omarchy shell restarted'
else
  warn 'omarchy restart shell failed; the plugins will load after a reboot.'
fi
