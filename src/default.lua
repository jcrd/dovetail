local default = {}

local colors = {
    fg = '#444444',
    bg = '#fafafa',
    bg_alt = "#bcbcbc",
    focus = '#005f87',
}

default.theme = {
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
    border_normal_floating = colors.bg_alt,
    notification_border_color = colors.fg,

    fg_focus = colors.bg,
    bg_focus = colors.focus,
    border_focus = colors.focus,

    desktop_wallpaper = colors.bg,

    clock_format = '<span size=\'smaller\' rise=\'1000\'></span> %a, %b %e  %l:%M%P',
}

default.options = {
    default_workspace_name = 'main',
    new_workspace_name = 'scratch',
    workspace_search_paths = {},
    backlight_name = 'default',
    brightness_step = 10,
    inc_brightness_cmd = nil,
    dec_brightness_cmd = nil,
    hide_mouse_on_startup = true,
    battery_low_percent = 10,
    battery_charged_percent = 95,
    enable_battery_widget = os.getenv('CHASSIS') == 'laptop',
}

return default
