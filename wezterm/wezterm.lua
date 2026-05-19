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
-- Tab bar — bar.wezterm handles tab titles + right-side status modules
----------------------------------------------------------------------
config.use_fancy_tab_bar = false           -- bar.wezterm needs retro tab bar
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 36

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

----------------------------------------------------------------------
-- bar.wezterm — right-side status modules
-- Modules disabled to avoid overlap with Claude Code's own status line:
--   cwd, cmd, username  (CC already shows these / not useful locally)
-- Modules kept: pane (current process), workspace, hostname, clock
----------------------------------------------------------------------
local bar = wezterm.plugin.require('https://github.com/adriankarlen/bar.wezterm')
bar.apply_to_config(config, {
  position = 'top',
  max_width = 32,
  padding = { left = 1, right = 1 },
  separator = {
    space = 1,
    left_icon = wezterm.nerdfonts.fa_long_arrow_right,
    right_icon = wezterm.nerdfonts.fa_long_arrow_left,
    field_icon = wezterm.nerdfonts.indent_line,
  },
  modules = {
    username  = { enabled = false },
    hostname  = { enabled = true,  icon = wezterm.nerdfonts.cod_server },
    clock     = { enabled = true,  icon = wezterm.nerdfonts.md_clock_time_three_outline },
    cwd       = { enabled = false },
    cmd       = { enabled = false },
    workspace = { enabled = true,  icon = wezterm.nerdfonts.cod_window },
    pane      = { enabled = true,  icon = wezterm.nerdfonts.cod_multiple_windows },
    spotify   = { enabled = false },
    zoxide    = { enabled = false },
  },
})

return config
