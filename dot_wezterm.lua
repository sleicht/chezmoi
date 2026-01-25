local wezterm = require 'wezterm'

local config = wezterm.config_builder()
config:set_strict_mode(true)

config.color_scheme = 'Dracula (Official)'
config.colors = {
  visual_bell = '#414868',
}
config.enable_scroll_bar = true
config.exit_behavior = 'CloseOnCleanExit'
config.exit_behavior_messaging = 'Verbose'
config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'BlexMono Nerd Font Mono',
  'FiraCode Nerd Font Mono',
  'NotoMono Nerd Font',
  'NotoSansM Nerd Font'
})
config.font_size = 12
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 134
config.initial_rows = 34
config.macos_window_background_blur = 20
config.notification_handling = "AlwaysShow"
config.scrollback_lines = 10000
config.swallow_mouse_click_on_pane_focus = false
config.use_fancy_tab_bar = true
config.tab_and_split_indices_are_zero_based = false
config.visual_bell = {
  fade_in_duration_ms = 150,
  fade_out_duration_ms = 150,
}
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.window_background_opacity = 0.95

config.use_dead_keys = false
config.adjust_window_size_when_changing_font_size = false
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7
}
config.window_frame = {
  font = wezterm.font { family = 'Noto Sans', weight = 'Regular' },
}

config.disable_default_key_bindings = true
config.leader = { key = 'a', mods = 'SUPER|CTRL|SHIFT', timeout_milliseconds = 1000 }
config.keys = {
  { key = 'n',          mods = 'SUPER',            action = wezterm.action.SpawnWindow },
  { key = 'm',          mods = 'SUPER',            action = wezterm.action.Hide },
  { key = 'Tab',        mods = 'CTRL|ALT',         action = wezterm.action.ActivateWindowRelative(1) },
  { key = 'Tab',        mods = 'CTRL|ALT|SHIFT',   action = wezterm.action.ActivateWindowRelative(-1) },
  { key = 'Enter',      mods = 'ALT',              action = wezterm.action.ToggleFullScreen },

  { key = 't',          mods = 'SUPER',            action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 't',          mods = 'SUPER|SHIFT',      action = wezterm.action.SpawnTab 'DefaultDomain' },
  { key = 't',          mods = 'SUPER|CTRL|SHIFT', action = wezterm.action.ShowTabNavigator },
  { key = 'w',          mods = 'SUPER',            action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'x',          mods = 'CMD',              action = wezterm.action.CloseCurrentPane { confirm = false } },
  { key = '1',          mods = 'SUPER',            action = wezterm.action.ActivateTab(0) },
  { key = '2',          mods = 'SUPER',            action = wezterm.action.ActivateTab(1) },
  { key = '3',          mods = 'SUPER',            action = wezterm.action.ActivateTab(2) },
  { key = '4',          mods = 'SUPER',            action = wezterm.action.ActivateTab(3) },
  { key = '5',          mods = 'SUPER',            action = wezterm.action.ActivateTab(4) },
  { key = '6',          mods = 'SUPER',            action = wezterm.action.ActivateTab(5) },
  { key = '7',          mods = 'SUPER',            action = wezterm.action.ActivateTab(6) },
  { key = '8',          mods = 'SUPER',            action = wezterm.action.ActivateTab(7) },
  { key = '9',          mods = 'SUPER',            action = wezterm.action.ActivateTab(8) },
  { key = '0',          mods = 'SUPER',            action = wezterm.action.ActivateTab(9) },
  { key = 'Tab',        mods = 'CTRL',             action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab',        mods = 'CTRL|SHIFT',       action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'LeftArrow',  mods = 'SUPER|SHIFT',      action = wezterm.action.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'SUPER|SHIFT',      action = wezterm.action.MoveTabRelative(1) },

  { key = 'f',          mods = 'OPT',              action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, },
  { key = 'd',          mods = 'OPT',              action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = 'h',          mods = 'OPT',              action = wezterm.action.ActivatePaneDirection 'Left', },
  { key = 'l',          mods = 'OPT',              action = wezterm.action.ActivatePaneDirection 'Right', },

  { key = "LeftArrow",  mods = "OPT",              action = wezterm.action.SendKey({ mods = "ALT", key = "b" }) },
  { key = "RightArrow", mods = "OPT",              action = wezterm.action.SendKey({ mods = "ALT", key = "f" }) },
  { key = "LeftArrow",  mods = "CMD",              action = wezterm.action.SendKey({ mods = "CTRL", key = "a" }) },
  { key = "RightArrow", mods = "CMD",              action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },
  { key = "Backspace",  mods = "CMD",              action = wezterm.action.SendKey({ mods = "CTRL", key = "u" }) },
  { key = "LeftArrow",  mods = "CMD|OPT",          action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CMD|OPT",          action = wezterm.action.ActivateTabRelative(1) },
  { key = "LeftArrow",  mods = "CMD|SHIFT",        action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CMD|SHIFT",        action = wezterm.action.ActivateTabRelative(1) },

  { key = '-',          mods = 'SUPER',            action = wezterm.action.DecreaseFontSize },
  { key = '=',          mods = 'SUPER',            action = wezterm.action.IncreaseFontSize },
  { key = '0',          mods = 'SUPER',            action = wezterm.action.ResetFontSize },
  { key = '0',          mods = 'SUPER|SHIFT',      action = wezterm.action.ResetFontAndWindowSize },

  { key = 'UpArrow',    mods = 'SUPER|SHIFT',      action = wezterm.action.ScrollByLine(-1) },
  { key = 'DownArrow',  mods = 'SUPER|SHIFT',      action = wezterm.action.ScrollByLine(1) },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT',       action = wezterm.action.ScrollByPage(-0.5) },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT',       action = wezterm.action.ScrollByPage(0.5) },
  { key = 'UpArrow',    mods = 'SUPER|ALT|SHIFT',  action = wezterm.action.ScrollToTop },
  { key = 'DownArrow',  mods = 'SUPER|ALT|SHIFT',  action = wezterm.action.ScrollToBottom },
  { key = 'UpArrow',    mods = 'CTRL|ALT|SHIFT',   action = wezterm.action.ScrollToTop },
  { key = 'DownArrow',  mods = 'CTRL|ALT|SHIFT',   action = wezterm.action.ScrollToBottom },

  { key = 'p',          mods = 'SUPER|CTRL|SHIFT', action = wezterm.action.ActivateCommandPalette },
  { key = 'n',          mods = 'SUPER|CTRL|SHIFT', action = wezterm.action.ShowLauncher },

  { key = 'f',          mods = 'SUPER',            action = wezterm.action.Search('CurrentSelectionOrEmptyString') },
  { key = 'u',          mods = 'CTRL|SHIFT',       action = wezterm.action.CharSelect },
  { key = 'k',          mods = 'SUPER',            action = wezterm.action.Multiple { wezterm.action.ClearScrollback 'ScrollbackAndViewport', wezterm.action.SendKey { key = 'L', mods = 'CTRL' } } },
  { key = 'j',          mods = 'OPT',              action = wezterm.action.ActivatePaneDirection 'Down', },
  { key = 'k',          mods = 'OPT',              action = wezterm.action.ActivatePaneDirection 'Up', },
  { key = 'x',          mods = 'CTRL|SHIFT',       action = wezterm.action.ActivateCopyMode },
  { key = 'Enter',      mods = 'OPT',              action = wezterm.action.ActivateCopyMode },
  { key = ' ',          mods = 'SUPER|ALT|SHIFT',  action = wezterm.action.QuickSelect },

  { key = 'c',          mods = 'SUPER',            action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v',          mods = 'SUPER',            action = wezterm.action.PasteFrom 'Clipboard' },

  { key = 'r',          mods = 'SUPER',            action = wezterm.action.ReloadConfiguration },
  { key = 'l',          mods = 'CTRL|SHIFT',       action = wezterm.action.ShowDebugOverlay },
  { key = 'h',          mods = 'SUPER',            action = wezterm.action.HideApplication },
  { key = 'q',          mods = 'SUPER',            action = wezterm.action.QuitApplication },
}

return config
