local colors = {
    fg = '#444444',
    bg = '#fafafa',
    bg_alt = "#bcbcbc",
    focus = '#005f87',
}

theme {
    font_name = 'monospace',
    font_size = 12,
    bar_growth = 4,
    info_margins = 10,

    master_width = 0.6,

    useless_gap = 2,
    gap_single_client = false,

    border_width = 2,
    notification_border_width = 1,

    fg_normal = colors.fg,
    bg_normal = colors.bg,
    bg_normal_alt = colors.bg_alt,
    border_normal = colors.bg,
    notification_border_color = colors.fg,

    fg_focus = colors.bg,
    bg_focus = colors.focus,
    border_focus = colors.focus,

    desktop_wallpaper = colors.bg,

    clock_format = '<span size=\'smaller\' rise=\'1000\'></span> %a, %b %e  %l:%M%P',
}

options {
    default_workspace_name = 'main',
    new_workspace_name = 'scratch',
    workspace_search_paths = {},
    backlight_name = 'default',
    brightness_step = 10,
    hide_mouse_on_startup = true,
    battery_low_percent = 10,
    battery_charged_percent = 95,
}

notifications {
    position = 'top_middle',
    timeout = 5,
}

local clients = {
    chromium = {
        cmd = 'chromium',
        factory = 'chromium',
    },
    terminal = {
        cmd = 'kitty',
        set_master = true,
    },
    panel = {
        cmd = 'kitty',
        id = 'panel_terminal',
        scale = 0.6,
    },
}

workspace_clients(clients)

keys {
    -- Menu.
    ['M-p'] = cmd.menu.run,
    ['M-S-p'] = cmd.menu.run_workspace,
    ['M-w'] = cmd.menu.new_workspace,
    ['M-r'] = cmd.menu.rename_workspace,

    -- Launch clients.
    ['M-Return'] = {cmd.launch, clients.terminal},
    ['M-grave'] = {cmd.workspace.toggle_panel, clients.panel},

    -- Workspaces.
    ['M-Tab'] = cmd.workspace.restore,
    ['M-S-j'] = cmd.workspace.next,
    ['M-S-k'] = cmd.workspace.prev,
    ['M-<numrow>'] = cmd.workspace.view,
    ['M-S-<numrow>'] = cmd.client.follow_to_workspace,
    ['M-C-<numrow>'] = cmd.client.move_to_workspace,
    ['M-period'] = {cmd.workspace.adjust_master_width, 0.1},
    ['M-comma'] = {cmd.workspace.adjust_master_width, -0.1},

    -- Clients.
    ['M-j'] = cmd.client.focus.next,
    ['M-k'] = cmd.client.focus.prev,
    ['M-f'] = cmd.client.focus.other,
    ['M-S-f'] = cmd.client.focus.other_layer,
    ['M-o'] = cmd.client.toggle_max,

    -- Session.
    ['M-BackSpace'] = cmd.session.lock,
    ['M-Up'] = cmd.session.brightness.inc,
    ['M-Down'] = cmd.session.brightness.dec,

    -- Audio.
    ['XF86AudioLowerVolume'] = {cmd.audio.adjust, -2},
    ['XF86AudioRaiseVolume'] = {cmd.audio.adjust, 2},
    ['XF86AudioMute'] = cmd.audio.toggle,

    -- Window manager.
    ['M-C-r'] = cmd.wm.restart,
    ['M-C-q'] = cmd.wm.quit,

    -- System.
    ['M-C-minus'] = cmd.system.poweroff,
    ['M-C-equal'] = cmd.system.suspend,

    -- Misc.
    ['M-m'] = cmd.mouse.hide,
    ['M-d'] = cmd.notification.destroy_all,

}

client_keys {
    ['M-s'] = cmd.client.set_master,
    ['M-S-d'] = cmd.client.close,
    ['M-space'] = cmd.client.toggle_floating,
    ['M-g'] = cmd.client.toggle_fullscreen,
    ['M-n'] = cmd.client.normalize,
}

buttons {
    ['1'] = cmd.mouse.focus,
    ['M-1'] = cmd.mouse.move,
    ['M-1'] = cmd.mouse.resize,
}

rules {
    {
        rule = {class = 'Chromium'},
        names = 'Netflix',
        inhibit = true,
    },
}
