----------------
--- MONITORS ---
----------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
  output        = "DP-1", -- first monitor
  mode          = "3840x2160@120", -- using 120 Hz for 10 bit color support
  position      = "0x0",
  scale         = 1,
  transform     = 0,
  bitdepth      = 10,
  vrr           = 1,
  supports_hdr  = 1,
})


hl.monitor({
  output        = "DP-2", -- vertical monitor right
  mode          = "3840x2160@120", -- using 120 Hz for 10 bit color support
  position      = "3840x-1000",
  scale         = 1,
  transform     = 3, -- rotated 270
  bitdepth      = 10,
  vrr           = 1,
  supports_hdr  = 1,
})

hl.monitor({
  output        = "DP-3", -- vertical monitor left
  mode          = "3840x2160@120", -- using 120 Hz for 10 bit color support
  position      = "-2160x-1000",
  scale         = 1,
  transform     = 1, -- rotated 90
  bitdepth      = 10,
  vrr           = 1,
  supports_hdr  = 1,
})

hl.monitor({
  output        = "", -- default monitor
  mode          = "preferred",
  position      = "auto",
  scale         = "auto",
})


-------------------
--- MY PROGRAMS ---
-------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = terminal .. " nnn"
local menu        = "rofi -show drun"
local browser     = "chromium"


-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("EDITOR", "/usr/bin/nvim")


-----------------
--- AUTOSTART ---
-----------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function ()
  hl.exec_cmd("hyprpaper & waybar & hypridle & clipse -listen") -- desktop misc
  hl.exec_cmd("openrgb -p Blank.orp") -- RGB lights
  hl.exec_cmd("solaar -w hide --restart-on-wake-up") -- Logtitech mouse
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- screen sharing config
  hl.exec_cmd("hyprlock") -- start lockscreen last
end)


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons


---------------------
--- LOOK AND FEEL ---
---------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
  general = { 
    gaps_in  = 5,
    gaps_out = 5,

    border_size = 2,

    col = {
      active_border   = {colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45},
      inactive_border = "rgba(595959aa)",
    },

    -- Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false, 

    -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
    allow_tearing = false,

    layout = "dwindle",
  },

  decoration = {
    rounding        = 1,
    rounding_power  = 2,

    -- Change transparency of focused and unfocused windows
    active_opacity    = 1.0,
    inactive_opacity  = 1.0,
    
    shadow = {
      enabled       = true,
      range         = 4,
      render_power  = 3,
      color         = "rgba(1a1a1aee)",
    },

    blur = {
      enabled   = true,
      size      = 3,
      passes    = 1,
      vibrancy  = 0.1696,
    },
  },

  -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
  dwindle = {
    preserve_split = true, -- You probably want this
  },
  
  -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
  master = {
    new_status = "master",
  },

  -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
  scrolling = {
    fullscreen_on_one_column = true,
  },

  misc = { 
      force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
      disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
  },

  ecosystem = {
      no_update_news  = true, -- Do not show alert after update
      no_donation_nag = true, -- Do not show semi-annual donation pop-up
  },

  animations = {
      enabled = true,
  },
})


----------------
-- Animations --
----------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- bezier curves
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1},    {0.3, 1}     } })
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- spring curves
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- animations
hl.animation({ leaf = "windows",      enabled = true, speed = 7,  bezier = "easeOutExpo" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 7,  bezier = "default",       style = "popin 80%" })
hl.animation({ leaf = "fade",         enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "border",       enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",  enabled = true, speed = 8,  bezier = "default",       style = "once" })


-------------
--- INPUT ---
-------------

hl.config({
  input = {
    kb_layout           = "us",
    numlock_by_default  = true,

    follow_mouse = 2, -- cursor focus is detached from keyboard focus. Clicking the window moves keyboard focus

    accel_profile = "flat",
    sensitivity   = 0, -- no modification.
  },
})


------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
hl.window_rule({
  -- clipse
  name  = "clipse",
  match = { class = "^(clipse)$" },

  float = true, 
  size  = {650, 450},
})

hl.window_rule({
  -- Ignore maximize requests from all apps. You'll probably like this.
  name  = "suppress-maximize-events",
  match = { class = ".*" },

  suppress_event = "maximize",
})

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})


-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"                     -- Sets "Windows" key as main modifier
local mainModShift = mainMod .. " + SHIFT"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
-- Open Apps
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(terminal .. " --class clipse -e 'clipse'"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

-- Modify windows
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())                      -- dwindle
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))                -- dwindle
hl.bind(mainMod .. " + F",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + return", hl.dsp.window.fullscreen())

-- Close apps / hyprland
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + C",      hl.dsp.window.close())
hl.bind(mainModShift .. " + C", hl.dsp.window.kill())
hl.bind(mainModShift .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown > /dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",   hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",  hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",     hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",   hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + F[1-24] (F[13-24] requires using scan code)
-- Move active window to a workspace with mainMod + SHIFT + F[1-24] (F[13-24] requires using scan code)
for i = 1, 12 do
  local key = "F" .. i -- F1 through F12

  hl.bind(mainMod .. " + " .. key,      hl.dsp.focus({ workspace = i }))
  hl.bind(mainModShift .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

for i = 13, 24 do
  local keyNum = i + 178        -- keycodes start at 191 and go to 202
  local key = "code:" .. keyNum -- F13 through F24

  hl.bind(mainMod .. " + " .. key,      hl.dsp.focus({ workspace = i }))
  hl.bind(mainModShift .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",      hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainModShift .. " + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),    { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(),  { mouse = true })

-- multimedia keys 
-- all locked
-- up/down are also repeating
hl.bind("XF86AudioMute",                        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),                { locked = true })                    -- FN1(Mute) = Mute volume
hl.bind("CTRL + XF86AudioMute",                 hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),              { locked = true })                    -- Shift+FN1(Mute) = Mute Mic
hl.bind("SHIFT + XF86AudioRaiseVolume",         hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0"),                 { locked = true })                    -- Shift+FN3 (Vol+) = Reset Volume
hl.bind("CTRL + SHIFT + XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.7"),               { locked = true })                    -- Ctrl+Shift+FN3 (Vol+) = Reset Mic Volume
hl.bind("XF86AudioRaiseVolume",                 hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0"),     { locked = true, repeating = true })  -- FN3 (Vol+) = Volume Up
hl.bind("XF86AudioLowerVolume",                 hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),                 { locked = true, repeating = true })  -- FN5 (Vol-) = Volume Down 
hl.bind("CTRL + XF86AudioRaiseVolume",          hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ --limit 1.7"),   { locked = true, repeating = true })  -- Ctrl+FN3 (Vol+) = Mic Volume Up
hl.bind("CTRL + XF86AudioLowerVolume",          hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"),               { locked = true, repeating = true })  -- Ctrl+FN5 (Vol-) = Mic Volume Down 
