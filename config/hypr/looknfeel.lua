-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
    general = {
        -- No gaps between windows or borders.
        gaps_in = 2,
        gaps_out = 0,
        border_size = 1,

        -- Change to niri-like side-scrolling layout.
        -- layout = "scrolling",
    },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
    decoration = {
        -- Use round window corners.
        rounding = 10,

        -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
        dim_inactive = true,
        dim_strength = 0.15,

        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            xray = false, -- blur windows underneath too, not just the wallpaper
            noise = 0.02,
            brightness = 1.0,
            vibrancy = 0.2,
        },
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = 0x66000000,
        },
    },
})
hl.window_rule({
    name    = "transparent-windows",
    match   = { class = ".*" },
    opacity = "0.85 0.75", -- active, inactive
})

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
    scrolling = {
        -- See only one column per screen instead of two.
        column_width = 0.97,
    },
})

-- No border or rounding when a workspace has a single tiled window.
hl.workspace_rule({ workspace = "w[tv1]", gaps_in = 0, gaps_out = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_in = 0, gaps_out = 0 })

hl.window_rule({
    name        = "single-window-no-border",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name        = "fullscreen-no-border",
    match       = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})
