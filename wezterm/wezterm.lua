-- ~/.wezterm.lua  (symlinked from dotfiles/wezterm/wezterm.lua)
-- Cross-platform; tweak via the `is_windows` / `is_mac` blocks at the bottom.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

----------------------------------------------------------------------
-- Shell
----------------------------------------------------------------------
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

----------------------------------------------------------------------
-- Font
----------------------------------------------------------------------
config.font = wezterm.font_with_fallback({
  { family = 'Maple Mono NF CN', weight = 'Regular' },
  { family = 'Microsoft YaHei' },
  { family = 'Segoe UI Emoji' },
})
config.font_size = 11.5
config.line_height = 1.10
config.cell_width = 1.0
config.harfbuzz_features = { 'calt=1', 'liga=1', 'clig=1' }
config.warn_about_missing_glyphs = false

----------------------------------------------------------------------
-- Theme — Tokyo Night Storm (built-in)
----------------------------------------------------------------------
config.color_scheme = 'Tokyo Night Storm'

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
config.initial_cols = 140
config.initial_rows = 38
config.window_padding = { left = 16, right = 16, top = 10, bottom = 8 }
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_background_opacity = 0.88
config.win32_system_backdrop = 'Acrylic'
config.macos_window_background_blur = 30

----------------------------------------------------------------------
-- Tab bar
----------------------------------------------------------------------
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 36

local function basename(s)
  return s:gsub('^.*[\\/]', ''):gsub('%.exe$', '')
end

wezterm.on('format-tab-title', function(tab, _, _, _, hover)
  local proc = basename(tab.active_pane.foreground_process_name or '')
  if proc == '' then proc = 'shell' end
  local title = string.format('  %d  %s  ', tab.tab_index + 1, proc)
  local bg = tab.is_active and '#24283b' or (hover and '#1f2335' or '#1a1b26')
  local fg = tab.is_active and '#c0caf5' or '#565f89'
  return { { Background = { Color = bg } }, { Foreground = { Color = fg } }, { Text = title } }
end)

----------------------------------------------------------------------
-- Cursor
----------------------------------------------------------------------
config.default_cursor_style = 'SteadyBar'
config.cursor_blink_rate = 0

----------------------------------------------------------------------
-- Behavior
----------------------------------------------------------------------
config.audible_bell = 'Disabled'
config.enable_scroll_bar = false
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false
config.front_end = 'WebGpu'
config.max_fps = 120
config.animation_fps = 60

----------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------
config.keys = {
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CTRL|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'F11', mods = '', action = act.ToggleFullScreen },
}

return config
