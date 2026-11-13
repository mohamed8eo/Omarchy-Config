-- Island keybindings, written by Island's setup. Change them in Island's
-- Settings → Keybinds; removing one gives the key back to Omarchy.
local function island(keys, description, command)
  hl.unbind(keys)
  o.bind(keys, description, "omarchy-shell guilhermerisu.island " .. command)
end

-- addons: ask,calendar,keyboard,plugins,pomodoro,prayers,timer,usage
island("SUPER + SPACE", "Omarchy Menu", "show menu")
island("SUPER + K", "Keybindings", "show keybinds")
island("SUPER + CTRL + E", "Emoji", "show emoji")
island("SUPER + CTRL + V", "Clipboard", "show clipboard")
island("SUPER + SHIFT + CTRL + SPACE", "Themes", "themes")
island("SUPER + CTRL + SPACE", "Wallpapers", "wallpapers")
island("SUPER + ESCAPE", "Power Menu", "power")
island("SUPER + ALT + P", "Now Playing", "show player")
island("CTRL + ALT + P", "Prayers", "show prayers")
island("CTRL + ALT + T", "Focus", "show pomodoro")

-- While Settings records a shortcut, the island switches to this submap so
-- the keys reach it instead of running their bindings. Its one bind leaves it.
hl.define_submap("island-record", function()
  hl.bind("SUPER + SHIFT + CTRL + ALT + ESCAPE", hl.dsp.submap("reset"))
end)
