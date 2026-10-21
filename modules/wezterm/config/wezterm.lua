local wezterm = require 'wezterm'

local config = wezterm.config_builder()
local act = wezterm.action

local host_specific = require 'host_specific'
local workspace_manager = require 'workspace_manager'
local which_key = require 'which_key'

-- TODO: Can InputSelector be inverted?
-- TODO: Investigate if there is a way to have a smaller window for Input selector (like command palette)
-- TODO: Fix which-key group assignment
--
-- Skip:
-- TODO: Make a few pre-configured workspaces (e.g. dotfiles, neovim config, home)

--------------------------------------------------------------------------------
-- Visuals settings
--------------------------------------------------------------------------------
config.window_decorations = 'RESIZE'
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.colors = {
  cursor_bg = 'white',
  -- cursor_border = "white",
}
config.window_background_opacity = 0.85
config.font = wezterm.font 'DaddyTimeMono Nerd Font'

for k, v in pairs(host_specific.config) do
  config[k] = v
end

--- Display workspace name and initialize workspace history
wezterm.on('update-status', function(window, pane)
  -- Initialize workspace history on first run
  workspace_manager:sync_with_active_workspaces()

  local cws = wezterm.mux.get_active_workspace()
  -- wezterm.log_info("current workspace: " .. cws)
  window:set_left_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Text = '[' .. cws .. ']' },
  })
end)

-- Force XWayland
config.enable_wayland = false

--------------------------------------------------------------------------------
-- Keybindings
--------------------------------------------------------------------------------
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }

config.keys = {
  -- {  -- Not working, yet
  --   key = "Space",
  --   mods = "LEADER",
  --   action = act.ShowLauncherArgs({ flags = "FUZZY|KEY_ASSIGNMENTS", title = "Keys" }),
  -- },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  -- Navigate Panes
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  -- Resize Panes
  { key = 'H', mods = 'ALT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'ALT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'ALT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'ALT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'LeftArrow', mods = 'ALT', action = act.AdjustPaneSize { 'Left', 1 } },
  { key = 'LeftArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'DownArrow', mods = 'ALT', action = act.AdjustPaneSize { 'Down', 1 } },
  { key = 'DownArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'UpArrow', mods = 'ALT', action = act.AdjustPaneSize { 'Up', 1 } },
  { key = 'UpArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'RightArrow', mods = 'ALT', action = act.AdjustPaneSize { 'Right', 1 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Tabs
  { key = 'n', mods = 'LEADER|CTRL', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER|CTRL', action = act.ActivateTabRelative(-1) },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = false } },
  { key = 'X', mods = 'LEADER', action = act.CloseCurrentTab { confirm = false } },
  { key = 'C', mods = 'LEADER', action = act.SpawnWindow },

  -- Launcher
  {
    key = 'S',
    mods = 'LEADER',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|WORKSPACES',
      title = 'launcher',
    },
  },
  {
    key = 'K',
    mods = 'LEADER',
    action = wezterm.action_callback(workspace_manager.workspace_selector_callback),
  },
  { key = 'L', mods = 'LEADER', action = wezterm.action_callback(workspace_manager.switch_to_last_workspace) },
  {
    key = '?',
    mods = 'LEADER|SHIFT',
    action = wezterm.action_callback(which_key.which_key_callback),
  },
}

return config
