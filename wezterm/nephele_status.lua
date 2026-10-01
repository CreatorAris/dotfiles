local wezterm = require 'wezterm'
local home = os.getenv('USERPROFILE') or os.getenv('HOME')
local cache_path = home .. '/.cache/wezterm/nephele-status.json'
local collector = home .. '/dotfiles/wezterm/nephele_status.py'
local python = 'E:/Nephele Workshop/venv/Scripts/pythonw.exe'
local cache = {}

local function metric(name, max_age, now)
  local entry = cache[name]
  if type(entry) ~= 'table' or type(entry.value) ~= 'table' then return {}, '?' end
  local stale = entry.error or now - (entry.fetched_at or 0) > max_age
  return entry.value, stale and '~' or ''
end

local function refresh_cache()
  local now = os.time()
  if now - (wezterm.GLOBAL.nephele_status_kick or 0) >= 10 then
    wezterm.GLOBAL.nephele_status_kick = now
    pcall(wezterm.background_child_process, { python, collector })
  end
  local file = io.open(cache_path, 'r')
  if file then
    local text = file:read('*a')
    file:close()
    local ok, parsed = pcall(wezterm.json_parse, text)
    if ok and type(parsed) == 'table' then cache = parsed end
  end
  return now
end

local function value(number, mark)
  if type(number) ~= 'number' then return '?' end
  return tostring(number) .. mark
end

local function summary(_)
  local now = refresh_cache()
  local online, on_mark = metric('presence', 40, now)
  return (wezterm.nerdfonts.md_account_multiple or '') .. ' ' .. value(online.online, on_mark)
end

local function freshness(name, mark, now)
  local entry = cache[name]
  if not entry or not entry.fetched_at then return '尚无有效数据' end
  local age = math.max(0, now - entry.fetched_at)
  local age_text = age < 60 and string.format('%.0f秒前', age) or string.format('%.0f分钟前', age / 60)
  return age_text .. (mark == '~' and '，数据过期' or '')
end

local function show_details(window, pane)
  local now = refresh_cache()
  local online, on_mark = metric('presence', 40, now)
  local api, api_mark = metric('api', 90, now)
  local telemetry, t_mark = metric('telemetry', 150, now)
  local rollout, r_mark = metric('rollout', 150, now)
  local gate = rollout.paused and '已暂停' or (rollout.percent and ('放量 ' .. rollout.percent .. '%') or '未知')
  local choices = {}
  local function row(label, color)
    table.insert(choices, { id = 'refresh', label = wezterm.format {
      { Foreground = { Color = color or '#c0caf5' } }, { Text = label },
    } })
  end
  local function section(title) row(title, '#bb9af7') end
  section('实时状态')
  row('在线账号       ' .. value(online.online, on_mark) .. ' 人', on_mark == '' and '#73daca' or '#e0af68')
  local rate = type(api.requests_5m) == 'number' and api.requests_5m > 0
    and type(api.errors_5m) == 'number' and string.format('%.1f%%', api.errors_5m / api.requests_5m * 100) or '无请求样本'
  row('API 近5分钟    ' .. value(api.errors_5m, api_mark) .. ' 次失败 / ' .. value(api.requests_5m, api_mark) .. ' 次请求',
    api_mark ~= '' and '#e0af68' or (api.errors_5m > 0 and '#f7768e' or '#73daca'))
  row('API 失败率     ' .. (api.requests_5m == nil and '未知' or rate) .. api_mark)
  if type(api.endpoints) == 'table' then
    row('端点 Top 5     失败优先，其次按请求量；下列数字为失败/请求', '#7a82a8')
    for _, endpoint in ipairs(api.endpoints) do
      row('  ' .. endpoint.endpoint .. '  ' .. value(endpoint.errors, api_mark) .. '/' .. value(endpoint.requests, api_mark),
        endpoint.errors > 0 and '#f7768e' or '#7a82a8')
    end
  end
  section('业务失败 · 报告数与受影响人数')
  row('今日 北京时间  ' .. value(telemetry.failure_users_today, t_mark) .. ' 人 / ' .. value(telemetry.failure_reports_today, t_mark) .. ' 条')
  row('近1小时        ' .. value(telemetry.failure_users_1h, t_mark) .. ' 人 / ' .. value(telemetry.failure_reports_1h, t_mark) .. ' 条')
  row('业务失败24h    ' .. value(telemetry.failure_users_24h, t_mark) .. ' 人 / ' .. value(telemetry.failure_reports_24h, t_mark) .. ' 条报告')
  row('PS插件阻断24h  ' .. value(telemetry.recorder_plugin_blocks_24h, t_mark) .. ' 个会话（重复开录仍计原始报告）')
  row('录制零帧短场次 ' .. value(telemetry.recorder_empty_users_24h, t_mark) .. ' 人 / '
    .. value(telemetry.recorder_empty_reports_24h, t_mark) .. ' 场；其中有漏录信号 '
    .. value(telemetry.recorder_empty_risk_users_24h, t_mark) .. ' 人 / '
    .. value(telemetry.recorder_empty_risk_reports_24h, t_mark) .. ' 场')
  local names = {
    client_error='客户端异常', recorder_start_failed='录制启动失败', recorder_stop_failed='录制收尾失败',
    lazy_window_load_failed='窗口加载失败', image_download_failed='图片下载失败', payment_failed='支付未完成',
    local_tool_used='工具执行失败', app_crash='未捕获异常',
  }
  if type(telemetry.failure_types) == 'table' then
    for _, item in ipairs(telemetry.failure_types) do
      row('  ' .. (names[item.event] or item.event) .. '  24h ' .. value(item.users, t_mark) .. ' 人 / ' .. value(item.reports, t_mark) .. ' 条')
    end
    if #telemetry.failure_types == 0 then row('  近24小时没有已记录的业务失败', '#73daca') end
  else
    row('  失败分类尚无有效数据', '#e0af68')
  end
  row('退出补报24h    ' .. value(telemetry.dirty_shutdown_reports_24h, t_mark) .. ' 条（非实时崩溃）')
  section('发布与更新')
  row('发布版本       ' .. (telemetry.version or '未知') .. t_mark)
  row('灰度配置       ' .. gate .. r_mark, rollout.paused and '#f7768e' or nil)
  if rollout.force_after_version then row('强制更新       低于 ' .. rollout.force_after_version .. ' 的版本' .. r_mark) end
  row('成功更新启动   24h ' .. value(telemetry.updated_24h, t_mark) .. ' 人 / 近1h ' .. value(telemetry.updated_1h, t_mark) .. ' 人')
  row('更新口径       确认启动到目标版本的去重人数；灰度百分比为配置值', '#7a82a8')
  section('数据源状态')
  row('在线来源       Relay · ' .. freshness('presence', on_mark, now), '#7a82a8')
  row('API 来源       Worker · ' .. freshness('api', api_mark, now), '#7a82a8')
  row('发布配置来源   远程配置 · ' .. freshness('rollout', r_mark, now), '#7a82a8')
  row('业务与更新来源 PostHog · ' .. freshness('telemetry', t_mark, now), '#7a82a8')
  row('统计说明       24h 为滚动窗口；遥测受统计开关和上报延迟影响', '#7a82a8')
  row('失败口径       同人跨分类会重复；业务失败不等同于服务故障', '#7a82a8')
  window:perform_action(wezterm.action.InputSelector {
    title = 'Nephele 运行概况 · ' .. os.date('%H:%M:%S', now),
    description = '打开时快照 · Enter 重新读取 · Esc 关闭 · ~ 数据过期 / ? 未知',
    choices = choices,
    action = wezterm.action_callback(function(w, p, id)
      if id then show_details(w, p) end
    end),
  }, pane)
end

return summary, show_details
