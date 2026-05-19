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
  -- tab_bar.background transparent so the bg image + tint show through the tab bar.
  -- The per-tab colors below are wezterm-native fallback; tabline.wez replaces
  -- most of this via its theme_overrides (see tabline.setup).
  tab_bar = {
    background = 'rgba:0 0 0 0',
    active_tab   = { bg_color = 'rgba:0 0 0 0', fg_color = '#c0caf5', intensity = 'Bold' },
    inactive_tab = { bg_color = 'rgba:0 0 0 0', fg_color = '#7a82a8' },
    inactive_tab_hover = { bg_color = 'rgba:0 0 0 0', fg_color = '#c0caf5', italic = false },
    new_tab        = { bg_color = 'rgba:0 0 0 0', fg_color = '#7a82a8' },
    new_tab_hover  = { bg_color = 'rgba:0 0 0 0', fg_color = '#c0caf5' },
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

-- Lift all foreground text 15% to improve contrast against background image,
-- especially for cc's own gray output (thinking blocks, tool details, line numbers)
-- which uses true-color hex codes not affected by the color scheme.
config.foreground_text_hsb = { brightness = 1.15, saturation = 1.0, hue = 1.0 }

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

-- IME — fix Windows IME (Microsoft Pinyin) candidate window drifting away
-- from the caret on first keystroke / after backspace.
-- 'System' hands rendering to the OS IME so it positions itself.
config.use_ime = true
config.ime_preedit_rendering = 'System'

----------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------
config.keys = {
  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
  -- Alt+1..9 to jump directly to tab N (wezterm default is Ctrl+Shift+digit;
  -- explicitly binding Alt+digit to match the convention I claimed earlier)
  { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
  { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
  { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
  { key = '6', mods = 'ALT', action = act.ActivateTab(5) },
  { key = '7', mods = 'ALT', action = act.ActivateTab(6) },
  { key = '8', mods = 'ALT', action = act.ActivateTab(7) },
  { key = '9', mods = 'ALT', action = act.ActivateTab(8) },

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
-- Custom tabline components — sync wezterm.run_child_process with
-- throttled cache so update-status (~1Hz) doesn't fork external procs
-- every tick. Each function returns the cached string except every Nth
-- second when it refreshes.
----------------------------------------------------------------------

local function fmt_speed(bps)
  if bps < 1024            then return string.format('%dB/s',   bps)
  elseif bps < 1024 * 1024 then return string.format('%.1fKB/s', bps / 1024)
  else                          return string.format('%.1fMB/s', bps / 1048576)
  end
end

-- GPU% via nvidia-smi (2s throttle).
local _gpu_t, _gpu_v = 0, '?'
local function gpu_pct()
  local now = os.time()
  if now - _gpu_t >= 2 then
    _gpu_t = now
    local ok, stdout = wezterm.run_child_process({
      'nvidia-smi',
      '--query-gpu=utilization.gpu',
      '--format=csv,noheader,nounits',
    })
    if ok and stdout then
      local pct = stdout:gsub('[^%d]', '')
      if pct ~= '' then _gpu_v = pct .. '%' end
    end
  end
  return 'GPU ' .. _gpu_v
end

-- Network speed: PowerShell Get-NetAdapterStatistics diff (3s throttle).
local _net_t, _net_rx, _net_tx, _net_v = 0, nil, nil, '?'
local function netspeed()
  local now = os.time()
  if now - _net_t >= 3 then
    local interval = now - _net_t
    _net_t = now
    local ok, stdout = wezterm.run_child_process({
      'powershell', '-NoProfile', '-Command',
      "$a = Get-NetAdapterStatistics | Where-Object {$_.Name -notmatch 'Loopback|isatap|Pseudo'} | Select-Object -First 1; \"$($a.ReceivedBytes),$($a.SentBytes)\"",
    })
    if ok and stdout then
      local rx, tx = stdout:match('(%d+),(%d+)')
      if rx and tx then
        rx, tx = tonumber(rx), tonumber(tx)
        if _net_rx and _net_tx and interval > 0 then
          local d_rx = math.max(0, (rx - _net_rx) / interval)
          local d_tx = math.max(0, (tx - _net_tx) / interval)
          _net_v = string.format('↓%s ↑%s', fmt_speed(d_rx), fmt_speed(d_tx))
        end
        _net_rx, _net_tx = rx, tx
      end
    end
  end
  return _net_v
end

-- Public IP via ipinfo.io (5min cache — IP rarely changes).
local _ip_t, _ip_v = 0, '?'
local function public_ip()
  local now = os.time()
  if now - _ip_t >= 300 then
    _ip_t = now
    local ok, stdout = wezterm.run_child_process({
      'curl', '-s', '-m', '3', 'https://ipinfo.io/ip',
    })
    if ok and stdout then
      _ip_v = stdout:gsub('%s', '')
    end
  end
  return 'IP ' .. _ip_v
end

----------------------------------------------------------------------
-- tabline.wez — lualine-style status bar (replaced bar.wezterm 2026-05).
-- Built-in `cpu` and `ram` components mean we can see resource usage
-- without opening btop or alt-tabbing to Task Manager.
----------------------------------------------------------------------
local tabline = wezterm.plugin.require('https://github.com/michaelbrusegard/tabline.wez')
tabline.setup({
  options = {
    icons_enabled = true,
    theme = 'Tokyo Night Storm',
    tabs_enabled = true,
    section_separators   = { left = '', right = '' },
    component_separators = { left = '│', right = '│' },
    tab_separators       = { left = '', right = '' },
    -- Make every section background transparent so the wezterm bg image
    -- shows through. Differentiate sections by foreground color only.
    theme_overrides = {
      normal_mode = {
        a = { fg = '#bb9af7', bg = 'rgba:0 0 0 0' },  -- purple (workspace)
        b = { fg = '#c0caf5', bg = 'rgba:0 0 0 0' },  -- main fg (process)
        c = { fg = '#a9b1d6', bg = 'rgba:0 0 0 0' },  -- secondary fg
      },
      tab = {
        active         = { fg = '#bb9af7', bg = 'rgba:0 0 0 0' },
        inactive       = { fg = '#7a82a8', bg = 'rgba:0 0 0 0' },
        inactive_hover = { fg = '#c0caf5', bg = 'rgba:0 0 0 0' },
      },
    },
  },
  sections = {
    tabline_a = { 'workspace' },
    tabline_b = { 'process' },
    tabline_c = { ' ' },
    tab_active = {
      'index',
      { 'process', padding = { left = 0, right = 1 } },
      { 'output',  padding = 0 },   -- bell when this tab has unseen output
      { 'zoomed',  padding = 0 },
    },
    tab_inactive = {
      'index',
      { 'process', padding = { left = 0, right = 1 } },
      { 'output',  padding = 0 },
    },
    tabline_x = { gpu_pct, 'cpu', 'ram', netspeed },
    -- Single-user box; hostname dropped. Show seconds so the clock visibly ticks.
    tabline_y = { public_ip, { 'datetime', style = '%H:%M:%S' } },
    tabline_z = { ' ' },
  },
  extensions = {},
})

return config
