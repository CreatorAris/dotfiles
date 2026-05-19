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
-- Theme — Tokyo Night Storm (built-in) + per-element overrides
----------------------------------------------------------------------
config.color_scheme = 'Tokyo Night Storm'

-- Per-element overrides merge on top of the built-in scheme.
config.colors = {
  cursor_bg     = '#bb9af7',  -- purple cursor block
  cursor_fg     = '#1a1b26',  -- text under cursor reads as dark bg
  cursor_border = '#bb9af7',
  selection_bg  = '#364a82',  -- official Tokyo Night Storm selection
  selection_fg  = '#c0caf5',
  scrollbar_thumb = '#414868',
  visual_bell     = '#bb9af7',
  tab_bar = {
    background = '#1a1b26',
    active_tab   = { bg_color = '#24283b', fg_color = '#c0caf5', intensity = 'Bold' },
    inactive_tab = { bg_color = '#1a1b26', fg_color = '#7a82a8' },
    inactive_tab_hover = { bg_color = '#1f2335', fg_color = '#c0caf5', italic = false },
    new_tab        = { bg_color = '#1a1b26', fg_color = '#7a82a8' },
    new_tab_hover  = { bg_color = '#1f2335', fg_color = '#c0caf5' },
  },
}

-- Visual bell — silent flash instead of an audible beep on bell.
config.visual_bell = {
  fade_in_function    = 'EaseIn',
  fade_in_duration_ms = 75,
  fade_out_function   = 'EaseOut',
  fade_out_duration_ms = 75,
}

-- Default inactive-pane dimming is too heavy; soften it.
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.85 }

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
config.initial_cols = 140
config.initial_rows = 38
config.window_padding = { left = 18, right = 18, top = 12, bottom = 8 }
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_background_opacity = 1.0    -- bg image needs opaque window
-- config.win32_system_backdrop = 'Acrylic'   -- disabled when using bg image

----------------------------------------------------------------------
-- Background — two layers: dimmed image + Tokyo Night tint overlay
----------------------------------------------------------------------
local home = os.getenv('USERPROFILE') or os.getenv('HOME')
config.background = {
  {
    source = { File = home .. '/dotfiles/wezterm/assets/background.png' },
    horizontal_align = 'Center',
    vertical_align   = 'Middle',
    repeat_x = 'NoRepeat',
    repeat_y = 'NoRepeat',
    width  = 'Cover',
    height = 'Cover',
    opacity = 1.0,
    -- Tuned for the cyan-blue Miku image: image is palette-friendly to
    -- Tokyo Night already, so less aggressive dimming/desaturation.
    hsb = { brightness = 0.32, saturation = 0.80, hue = 1.0 },
  },
  {
    -- Tokyo Night Storm base color, semi-transparent, glues the palette together.
    -- 0.65 (was 0.45) — heavier tint so foreground text stays readable
    -- against the brighter sky regions of the background image.
    source = { Color = '#1a1b26' },
    width  = '100%',
    height = '100%',
    opacity = 0.65,
  },
}

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
  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },

  -- Panes — split
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CTRL|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  -- Panes — focus (vim h/j/k/l = left/down/up/right)
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  -- Panes — zoom toggle (current pane fills the tab, press again to restore)
  { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
  -- Panes — close current pane (kills the process inside)
  { key = 'q', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },

  -- Misc
  { key = 'r',   mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = 'F11', mods = '',           action = act.ToggleFullScreen },
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
