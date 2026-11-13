-- ==========================================
-- Unbind default shortcuts being overridden
-- ==========================================
hl.unbind("SUPER + SHIFT + C")   -- open Hey
hl.unbind("SUPER + SHIFT + E")   -- open Hey
hl.unbind("SUPER + SHIFT + S")   -- open google maps
hl.unbind("SUPER + SHIFT + A")   -- open Chatgpt twice
hl.unbind("SUPER + SHIFT + W")   -- open Omwrite
hl.unbind("SUPER + SHIFT + M")   -- install spotify
hl.unbind("SUPER + SHIFT + G")   -- install signal
hl.unbind("SUPER + ALT + SPACE") -- apps finder
hl.unbind("SUPER + SHIFT + P")   --  Google photo
hl.unbind("SUPER + SHIFT + X")   --  Twitter


-- ==========================================
-- App Launchers
-- ==========================================
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("omarchy-launch-or-focus ^karing$ \"uwsm-app -- karing\""),
    { description = "karing-bin" })
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("omarchy-launch-or-focus ^obsidian$ \"uwsm-app -- obsidian\""),
    { description = "Obsidian" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("omarchy-launch-or-focus ^Claude$ \"uwsm-app -- claude-desktop\""),
    { description = "Claude" })
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("omarchy-launch-or-focus ^Perplexity$ \"uwsm-app -- Perplexity\""),
    { description = "Perplexity" })
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("omarchy-launch-or-focus ^Telegram$ \"uwsm-app -- Telegram\""),
    { description = "Telegram" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("omarchy-launch-or-focus ^Sioyek$ \"uwsm-app -- sioyek\""),
    { description = "Sioyek" })


-- ==========================================
-- Web App Shortcuts
-- ==========================================
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("omarchy-launch-webapp \"https://chatgpt.com\""),
    { description = "ChatGPT" })
-- hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd("omarchy-launch-webapp \"https://youtube.com/\""),
--     { description = "YouTube" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("omarchy-launch-or-focus-webapp WhatsApp \"https://web.whatsapp.com/\""),
    { description = "WhatsApp" })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("omarchy-launch-or-focus-webapp Gmail \"https://mail.google.com\""),
    { description = "Gmail" })
hl.bind("SUPER + SHIFT + G",
    hl.dsp.exec_cmd("omarchy-launch-or-focus-webapp Github \"https://github.com/mohamed8eo?tab=repositories\""),
    { description = "Github" })
-- hl.bind("SUPER + SHIFT + J",
--     hl.dsp.exec_cmd("omarchy-launch-or-focus-webapp Jellyfin \"http://localhost:8096/web/#/home\""),
--     { description = "Jellyfin" })


-- ==========================================
-- Navigation & Window Management (Vim-style)
-- ==========================================
-- Focus movement
hl.bind("ALT + H", hl.dsp.focus({ direction = "left" }), { description = "Move focus left" })
hl.bind("ALT + L", hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind("ALT + K", hl.dsp.focus({ direction = "up" }), { description = "Move focus up" })
hl.bind("ALT + J", hl.dsp.focus({ direction = "down" }), { description = "Move focus down" })

-- Swap window position
hl.bind("CTRL + SHIFT + H", hl.dsp.window.swap({ direction = "l" }), { description = "Swap window left" })
hl.bind("CTRL + SHIFT + L", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window right" })
hl.bind("CTRL + SHIFT + K", hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind("CTRL + SHIFT + J", hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- ==========================================
-- System & Hardware Controls
-- ==========================================
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("omarchy-capture-screenshot"), { description = "Screenshot" })

o.bind("ALT + F2", "Decrease brightness", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("ALT + F3", "Increase brightness", "omarchy-brightness-display +5%", { locked = true, repeating = true })

-- The stock volume-up script caps at 100%; use Island's boost range to 150%.
hl.unbind("XF86AudioRaiseVolume") -- was: Volume up (capped at 100%)
o.bind("XF86AudioRaiseVolume", "Volume up (boost to 150%)",
    "bash ~/.config/omarchy/plugins/mohamed.island/bin/volume-up.sh", { locked = true, repeating = true })


-- >>> spotlight setup tour (managed; rerun via "Run Setup Tour") >>>
o.bind("SUPER + ALT + SPACE", "Spotlight", "omarchy-shell shell toggle io.github.maajix.spotlight '{}'")
-- <<< spotlight setup tour <<<
-- o.bind("SUPER + SHIFT + L", "Lock screen (qylock Sword)", "/home/mohamed/.local/bin/qylock-lock")
