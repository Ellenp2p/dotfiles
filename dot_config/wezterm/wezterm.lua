-- WezTerm 跨平台终端模拟器配置
-- 定位：GPU 加速渲染、配合 Zellij 使用、三端一致

local wezterm = require 'wezterm'
local config = {}

-- ==================== 外观 ====================

-- 字体：Nerd Font 优先，回退系统字体
-- 提示：如果缺少 Nerd Font，图标会显示为方块，建议安装 JetBrainsMono Nerd Font
config.font = wezterm.font_with_fallback({
    'JetBrainsMono Nerd Font',
    'FiraCode Nerd Font',
    'Cascadia Code',
    'Consolas',
    'Menlo',
    'monospace',
})
config.font_size = 14.0

-- 行高
config.line_height = 1.2

-- 颜色主题
config.color_scheme = 'Catppuccin Mocha'

-- 窗口
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.95
config.initial_cols = 120
config.initial_rows = 35

-- 光标
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 800

-- ==================== 性能 ====================

-- 让 WezTerm 自动选择最佳渲染后端
-- config.front_end = 'WebGpu'  -- 如遇兼容问题可注释掉

-- 关闭滚动条，TUI 应用自己处理滚动
config.enable_scroll_bar = false

-- ==================== 键位 ====================
-- 原则：WezTerm 只管基础功能，多标签/分屏全部交给 Zellij

config.keys = {
    -- 复制粘贴
    { key = 'c', mods = 'SHIFT|CTRL', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'v', mods = 'SHIFT|CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
    
    -- 新建窗口
    { key = 'n', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnWindow },
    
    -- 字体缩放
    { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },
    
    -- 清屏（Zellij 接管后这条不常用，但保留备用）
    { key = 'l', mods = 'SHIFT|CTRL', action = wezterm.action.ClearScrollback 'ScrollbackAndViewport' },
}

-- ==================== 鼠标 ====================

config.enable_mouse_reporting = true
config.hide_mouse_cursor_when_typing = false

-- 鼠标选中即复制
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = wezterm.action.SelectTextAtMouseCursor 'Cell',
    },
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = wezterm.action.ExtendSelectionToMouseCursor 'Cell',
    },
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'SHIFT',
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
}

-- ==================== 默认 Shell ====================

-- macOS / Linux 原生：直接用 Fish
if wezterm.target_triple:find('apple') or wezterm.target_triple:find('linux') then
    config.default_prog = { 'fish', '-l' }
end

-- Windows：自动进入 WSL2（如检测到）
-- 如果 WSL 里装了 Ubuntu，取消下面注释
-- if wezterm.target_triple:find('windows') then
--     config.default_domain = 'WSL:Ubuntu'
-- end

-- ==================== Tab Bar ====================

-- 简化标签栏（Zellij 接管后其实看不到，但保留备用）
config.use_fancy_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.tab_bar_at_bottom = false

-- ==================== 杂项 ====================

-- 启动时检查更新
config.check_for_updates = true
config.check_for_updates_interval_hours = 168  -- 每周一次

-- 关闭时确认
config.window_close_confirmation = 'AlwaysPrompt'

-- 允许程序设置标题
config.window_title = "WezTerm"

return config
