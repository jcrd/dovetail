-- Table of colors used in the theme below.
local colors = {
    -- Foreground color.
    fg = '#444444',
    -- Background color.
    bg = '#fafafa',
    -- Alternative background color.
    bg_alt = "#bcbcbc",
    -- Focused color.
    focus = '#005f87',
}

-- The visual theme.
theme {
    -- Font for the bar, given as a Pango Font Description string without the size,
    -- e.g. `Liberation Mono`.
    font_name = 'monospace',
    -- Size of the font in pixels.
    font_size = 12,
    -- Space added to the top and bottom of the bar,
    -- i.e. bar height = `font_size` + `bar_padding`.
    bar_padding = 4,
    -- Space to the left and right of widgets in the bar's information area.
    info_margins = 10,

    -- Percentage of the screen occupied by the master client,
    -- given as a value between 0.1 and 1.0.
    master_width = 0.6,

    -- Space surrounding tiled clients.
    useless_gap = 2,
    -- Add space around clients even if only one is visible.
    gap_single_client = false,

    -- Width of borders around clients.
    border_width = 2,
    -- Width of borders around notifications.
    notification_border_width = 1,

    -- Normal foreground color of the bar's text.
    fg_normal = colors.fg,
    -- Normal background color of the bar.
    bg_normal = colors.bg,
    -- Alternative background color, used in the audio widget's volume bar.
    bg_normal_alt = colors.bg_alt,
    -- Border color of unfocused tiled clients.
    border_normal = colors.bg,
    -- Border color of unfocused floating clients.
    border_normal_floating = colors.bg_alt,
    -- Border color of notifications.
    notification_border_color = colors.fg,

    -- Focused foreground color of the bar's text.
    fg_focus = colors.bg,
    -- Focused background color of the bar.
    bg_focus = colors.focus,
    -- Border color of the focused client.
    border_focus = colors.focus,

    -- Path to image file or hex color to be used as the desktop wallpaper.
    desktop_wallpaper = colors.bg,

    -- Format of clock in the information area of the bar.
    -- See: https://developer.gnome.org/pygtk/stable/pango-markup-language.html
    clock_format = '<span size=\'smaller\' rise=\'1000\'></span> %a, %b %e  %l:%M%P',
}

-- General options.
options {
    -- Name of the main workspace.
    main_workspace_name = 'main',
    -- Name of a newly created workspace.
    scratch_workspace_name = 'scratch',
    -- Rename workspaces after the focused client's class.
    rename_scratch_workspaces = true,
    -- Paths to search for `.workspace` files.
    -- See: https://github.com/jcrd/wm-launch#workspace-files
    workspace_search_paths = {},
    -- Name of the backlight to control, as found in `/sys/class/backlight/<name>`.
    -- The special value `default` signifies the first backlight.
    backlight_name = 'default',
    -- Value by which to increment or decrement backlight brightness.
    brightness_step = 10,
    -- Hide the mouse pointer when the window manager starts.
    hide_mouse_on_startup = true,
    -- Allow maximized clients, workaround for clients that set maximized hints
    -- and therefore refuse to be tiled.
    allow_maximized_clients = false,
    -- Percentage at which you will be notified the battery is low.
    battery_low_percent = 10,
    -- Percentage at which you will be notified the battery is charged.
    battery_charged_percent = 95,
    -- Give volume feedback via notifications when a fullscreen client is
    -- focused.
    fullscreen_audio_notifications = true,
}

-- Notification options.
notifications {
    -- Notification position, one of:
    -- `top_right`, `top_left`, `bottom_left`, `bottom_right`,
    -- `top_middle`, `bottom_middle`, `middle`.
    position = 'top_middle',
    -- Time in seconds after which notifications expire.
    timeout = 5,
}

-- Table of clients.
local clients = {
    -- Web browser.
    chromium = {
        cmd = 'chromium',
        factory = 'chromium',
    },
    -- Terminal, launched as master client.
    terminal = {
        cmd = 'kitty',
        set_master = true,
    },
    -- Terminal, launched as centered pop-up panel.
    panel = {
        cmd = 'kitty',
        id = 'panel_terminal',
        scale = 0.6,
    },
}

-- Register workspace clients.
workspace_clients(clients)

-- Workspaces for use with `cmd.workspace.new`.
local workspaces = {
    -- Workspace with a terminal instance running `nvim`.
    edit = {
        name = 'edit',
        clients = { 'kitty -e nvim' },
    },
}

-- Global key bindings.
keys {
    -- Menu.
    -- Open application run menu.
    ['M-p'] = cmd.menu.run,
    -- Open application run menu and send launched client to a new workspace.
    ['M-S-p'] = cmd.menu.run_workspace,
    -- Create a new workspace from a `.workspace` file.
    ['M-w'] = cmd.menu.new_workspace,
    -- Prompt for new name of current workspace.
    ['M-r'] = cmd.menu.rename_workspace,
    -- Create `edit` workspace.
    ['M-e'] = {cmd.workspace.new, workspaces.edit},

    -- Launch clients.
    -- Launch main terminal instance.
    ['M-Return'] = {cmd.launch, clients.terminal},
    -- Toggle panel's visibility.
    ['M-grave'] = {cmd.workspace.toggle_panel, clients.panel},

    -- Workspaces.
    -- Select the previously selected workspace.
    ['M-Tab'] = cmd.workspace.restore,
    -- Select the next workspace, wrapping at the workspace list's end.
    ['M-S-j'] = cmd.workspace.next,
    -- Select the previous workspace, wrapping the workspace list's beginning.
    ['M-S-k'] = cmd.workspace.prev,
    -- Select the workspace corresponding to the number key pressed.
    ['M-<numrow>'] = cmd.workspace.view,
    -- Move a client to the specified workspace and select it.
    ['M-S-<numrow>'] = cmd.client.follow_to_workspace,
    -- Move a client to the specified workspace.
    ['M-C-<numrow>'] = cmd.client.move_to_workspace,
    -- Increase size of stack clients.
    ['M-period'] = {cmd.workspace.adjust_master_width, 0.1},
    -- Decrease size of stack clients.
    ['M-comma'] = {cmd.workspace.adjust_master_width, -0.1},

    -- Clients.
    -- Focus the next client in the stack.
    ['M-j'] = cmd.client.focus.next,
    -- Focus the previous client in the stack.
    ['M-k'] = cmd.client.focus.prev,
    -- Toggle focus between the master client and the top stack client.
    ['M-f'] = cmd.client.focus.other,
    -- Toggle focus between the tiled and floating layers.
    ['M-S-f'] = cmd.client.focus.other_layer,
    -- Maximize clients.
    ['M-o'] = cmd.client.toggle_max,
    -- Restore the most recently minimized client.
    ['M-S-x'] = cmd.client.unminimize,

    -- Session.
    -- Lock the screen.
    ['M-BackSpace'] = cmd.session.lock,
    -- Increase screen brightness.
    ['M-Up'] = cmd.session.brightness.inc,
    -- Decrease screen brightness.
    ['M-Down'] = cmd.session.brightness.dec,

    -- Audio.
    -- Decrease audio volume.
    ['XF86AudioLowerVolume'] = {cmd.audio.adjust, -2},
    -- Increase audio volume.
    ['XF86AudioRaiseVolume'] = {cmd.audio.adjust, 2},
    -- Toggle audio muted state.
    ['XF86AudioMute'] = cmd.audio.toggle,

    -- Screenshot.
    -- Take a screenshot, saved by default to `~/screenshots`.
    ['Print'] = cmd.screenshot.take,

    -- Window manager.
    -- Restart dovetail.
    ['M-C-r'] = cmd.wm.restart,
    -- Quit dovetail.
    ['M-C-q'] = cmd.wm.quit,

    -- System.
    -- Power off the system.
    ['M-C-minus'] = cmd.system.poweroff,
    -- Suspend the system.
    ['M-C-equal'] = cmd.system.suspend,

    -- Misc.
    -- Hide the mouse pointer.
    ['M-m'] = cmd.mouse.hide,
    -- Close all notifications.
    ['M-d'] = cmd.notification.destroy_all,
}

-- Key bindings that apply only to clients.
client_keys {
    -- Make the focused client the master client.
    ['M-s'] = cmd.client.set_master,
    -- Close the focused client.
    ['M-S-d'] = cmd.client.close,
    -- Toggle the focused client's floating state.
    ['M-space'] = cmd.client.toggle_floating,
    -- Toggle the focused client's fullscreen state.
    ['M-g'] = cmd.client.toggle_fullscreen,
    -- Normalize the state of the focused client.
    ['M-n'] = cmd.client.normalize,
    -- Minimize the focused client when a new client is launched.
    ['M-z'] = cmd.client.replace,
    -- Minimize the focused client.
    ['M-x'] = cmd.client.minimize,
}

-- Mouse button bindings.
buttons {
    -- Focus client under mouse pointer.
    ['1'] = cmd.mouse.focus,
    -- Move client under mouse pointer.
    ['M-1'] = cmd.mouse.move,
    -- Resize floating client under mouse pointer.
    ['M-3'] = cmd.mouse.resize,
}

-- Client rules.
rules {
    {
        -- Inhibit idling when a client with class 'Chromium' and name
        -- 'Netflix' has focus.
        rule = {class = 'Chromium'},
        names = 'Netflix',
        inhibit = true,
    },
}
