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
-- Tab bar — tabline.wez handles tab titles + right-side status modules
----------------------------------------------------------------------
config.use_fancy_tab_bar = false           -- tabline.wez needs retro tab bar
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 28

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
-- WebGpu lost its device on focus-switch (white-screen crash) and garbled
-- high-throughput output (cc large dumps). OpenGL is steadier on Windows.
config.front_end = 'OpenGL'
config.max_fps = 120
config.animation_fps = 60

-- Ctrl+C exits with 130 (SIGINT); cc and pwsh both use it for cancel. Treat
-- as clean so wezterm doesn't show the red "process exited with status 130"
-- overlay. 0 is clean by default.
config.clean_exit_codes = { 130 }

-- Close window without confirmation. cc state persists across sessions, and
-- the close-confirm prompt fires every Alt+F4 even when nothing is running.
config.window_close_confirmation = 'NeverPrompt'

-- Quick-select extras (Ctrl+Shift+Space): defaults already cover commit SHA /
-- UUID / IPv4 / URL / file paths. These add cc-workflow specifics.
config.quick_select_patterns = {
  [[#[0-9a-fA-F]{3,8}]],          -- hex colors
  [[:\d{2,5}\b]],                  -- ports like :8080
  [[v\d+\.\d+\.\d+(?:-[a-z]+)?]],  -- semver tags
}

-- IME: leave at wezterm defaults (use_ime=true + ime_preedit_rendering='Builtin').
-- Tried ime_preedit_rendering='System' 2026-05-20 to fix candidate window drift
-- with Microsoft Pinyin — it caused a crash on first Chinese input + broke Enter
-- on English. Reverted. The candidate-drift issue stands open; no quick fix.

----------------------------------------------------------------------
-- Clickable file:line jump to Cursor
-- cc frequently prints `path.ext:line` (sometimes with :col). Match those,
-- route through a synthetic `nephele-file://` scheme, then the open-uri
-- handler below resolves relative paths against the pane cwd and shells
-- out to `cursor --goto`. Keeps wezterm's default URL/email rules intact.
----------------------------------------------------------------------
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[\b((?:[A-Za-z]:[\\/])?[\w./\\-]+\.\w+):(\d+)(?::\d+)?\b]],
  format = 'nephele-file://$1:$2',
})

wezterm.on('open-uri', function(window, pane, uri)
  if not uri:find('^nephele%-file://') then return end

  local rest = uri:sub(#'nephele-file://' + 1)
  local file, line = rest:match('^(.+):(%d+)$')
  if not file then return false end

  local is_abs = file:match('^%a:[\\/]') or file:match('^[\\/][\\/]')
  if not is_abs then
    local cwd_url = pane:get_current_working_dir()
    if cwd_url then
      local cwd = cwd_url.file_path or ''
      cwd = cwd:gsub('[\\/]+$', '')
      if cwd ~= '' then file = cwd .. '/' .. file end
    end
  end

  wezterm.background_child_process({ 'cursor', '--goto', file .. ':' .. line })
  return false
end)

----------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------
config.keys = {
  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
  -- Rename current tab (manual override for differentiation)
  { key = ',', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
    description = 'Tab name:',
    action = wezterm.action_callback(function(window, _, line)
      if line then window:active_tab():set_title(line) end
    end),
  } },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
  -- Alt+1..9 to jump directly to tab N
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

-- Mouse: right-click pastes clipboard (additive — defaults like left-drag
-- select and Ctrl+click open-link are preserved).
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom 'Clipboard',
  },
}

----------------------------------------------------------------------
-- Tab rendering — show `<index>: <pane.title>` where pane.title is whatever
-- cc writes via OSC (includes its own state symbol like `·` prefix + the
-- session summary). Manual rename via Ctrl+Shift+, wins.
--
-- _G indirection: outer wezterm.on registers once, inner function hot-
-- reloads on Ctrl+Shift+R.
----------------------------------------------------------------------
_G._wez_handlers = _G._wez_handlers or {}
_G._wez_handlers.format_tab_title = function(tab, _, _, _, hover, _)
  local title
  if tab.tab_title ~= '' then
    title = tab.tab_title
  else
    title = tab.active_pane.title or ''
  end

  local index_color = tab.is_active and '#bb9af7' or (hover and '#c0caf5' or '#7a82a8')
  local title_color = tab.is_active and '#c0caf5' or '#7a82a8'

  return {
    { Foreground = { Color = index_color } },
    { Text = ' ' .. (tab.tab_index + 1) .. ': ' },
    { Foreground = { Color = title_color } },
    { Text = title .. ' ' },
  }
end

if not _G._wez_format_tab_title_registered then
  wezterm.on('format-tab-title', function(...)
    return _G._wez_handlers.format_tab_title(...)
  end)
  _G._wez_format_tab_title_registered = true
end

----------------------------------------------------------------------
-- Nephele Workshop — cached live operations metrics.
-- The background collector owns HTTP requests and per-source freshness.
----------------------------------------------------------------------
local nephele_status, nephele_details = dofile(home .. '/dotfiles/wezterm/nephele_status.lua')
wezterm.add_to_config_reload_watch_list(home .. '/dotfiles/wezterm/nephele_status.lua')
table.insert(config.keys, { key = 'i', mods = 'CTRL|ALT', action = wezterm.action_callback(nephele_details) })

----------------------------------------------------------------------
-- CPU load — replaces tabline's built-in `cpu` component.
-- The built-in runs `wmic cpu get loadpercentage`: (1) piped wmic stdout is
-- UTF-16LE, so `match('%d+')` stops at the first NUL and 37% renders as 3%;
-- (2) Win32_Processor.LoadPercentage under-reports on this Hyper-V host
-- (reads 1-14 while % Processor Time reads 20-60) and the query costs ~1.1s
-- of WMI provider time every 3s. This reads the raw PerfOS idle counter
-- (~200ms) and computes % Processor Time over the throttle window itself.
-- % Processor Utility (what Win11 Task Manager shows) is not used: with a
-- hypervisor present it reads 60-120% on this box regardless of real load.
----------------------------------------------------------------------
local cpu_last_fetch = 0
local cpu_prev_idle, cpu_prev_ts = nil, nil
local cpu_value = '·'

local function cpu_load(_)
  local now = os.time()
  if now - cpu_last_fetch >= 3 then
    cpu_last_fetch = now
    local ok, out = wezterm.run_child_process({
      'wmic.exe', 'path', 'Win32_PerfRawData_PerfOS_Processor',
      'where', "Name='_Total'",
      'get', 'PercentProcessorTime,Timestamp_Sys100NS', '/format:list',
    })
    if ok and out then
      out = out:gsub('%z', '')
      local idle = tonumber(out:match('PercentProcessorTime=(%d+)'))
      local ts = tonumber(out:match('Timestamp_Sys100NS=(%d+)'))
      if idle and ts then
        if cpu_prev_ts and ts > cpu_prev_ts then
          local busy = 100 - 100 * (idle - cpu_prev_idle) / (ts - cpu_prev_ts)
          cpu_value = string.format('%.0f', math.max(0, math.min(100, busy)))
        end
        cpu_prev_idle, cpu_prev_ts = idle, ts
      end
    end
  end
  return wezterm.nerdfonts.oct_cpu .. ' ' .. cpu_value .. '%'
end

----------------------------------------------------------------------
-- tabline.wez — lualine-style status bar
----------------------------------------------------------------------
local tabline = wezterm.plugin.require('https://github.com/michaelbrusegard/tabline.wez')
tabline.setup({
  options = {
    icons_enabled = true,
    theme = 'Tokyo Night Storm',
    -- Custom format-tab-title above renders tabs. tabline only does status bar.
    tabs_enabled = false,
    section_separators   = { left = '', right = '' },
    component_separators = { left = '│', right = '│' },
    tab_separators       = { left = '', right = '' },
    theme_overrides = {
      normal_mode = {
        a = { fg = '#bb9af7', bg = 'rgba:0 0 0 0' },
        b = { fg = '#c0caf5', bg = 'rgba:0 0 0 0' },
        c = { fg = '#a9b1d6', bg = 'rgba:0 0 0 0' },
      },
      tab = {
        active         = { fg = '#bb9af7', bg = 'rgba:0 0 0 0' },
        inactive       = { fg = '#7a82a8', bg = 'rgba:0 0 0 0' },
        inactive_hover = { fg = '#c0caf5', bg = 'rgba:0 0 0 0' },
      },
    },
  },
  sections = {
    -- Left side stays empty: workspace is always 'default', and tabline_b's
    -- `process` duplicates the per-tab process icon.
    tabline_a = {},
    tabline_b = {},
    tabline_c = { ' ' },
    -- tab_active/tab_inactive omitted: format-tab-title handler above
    -- renders all tabs with state icon + project color.
    tabline_x = { nephele_status, cpu_load },
    tabline_y = { { 'datetime', style = '%H:%M' } },
    tabline_z = { ' ' },
  },
  extensions = {},
})

return config
