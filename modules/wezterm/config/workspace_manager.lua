--------------------------------------------------------------------------------
-- Workspace Manager Module
--
-- Provides workspace history tracking with MRU (Most Recently Used) ordering
-- and enhanced workspace switching functionality for WezTerm.
--
-- Features:
-- - MRU workspace tracking (index 1 = current, index 2 = last)
-- - Automatic sync with active workspaces
-- - Last workspace switching (LEADER L keybinding)
-- - Enhanced workspace selector with MRU support
-- - Clean workspace list management
--
-- Data Structure:
-- wezterm.GLOBAL.workspace_history = {}  -- Simple MRU array
--   index 1 = current workspace
--   index 2 = last workspace
--   index 3+ = older workspaces
--------------------------------------------------------------------------------
local wezterm = require 'wezterm'
local act = wezterm.action

local module = {}

--- Checks if an item is in a table
---@param list table
---@param item any
---@return boolean
function module.list_contains(list, item)
  for _, x in ipairs(list) do
    if item == x then
      return true
    end
  end
  return false
end

--- Lazily initialize workspace history from wezterm.GLOBAL.
--- Deferring this (and all wezterm.mux / wezterm.GLOBAL access) until first use
--- is required: touching them while the config is still being evaluated makes
--- the GUI connection start before `enable_wayland = false` can take effect.
function module:ensure_initialized()
  if self.workspaces ~= nil then
    return
  end
  self.workspaces = {}
  for _, wp_name in ipairs(wezterm.GLOBAL.workspace_history or {}) do
    table.insert(self.workspaces, wp_name)
  end
end

--- Sync workspaces list with currently active workspaces
function module:sync_with_active_workspaces()
  self:ensure_initialized()
  local active_workspaces = wezterm.mux.get_workspace_names()

  for _, workspace in ipairs(active_workspaces) do
    if not module.list_contains(self.workspaces, workspace) then
      table.insert(self.workspaces, workspace)
    end
  end

  -- Remove any workspaces that are no longer active
  for i = #self.workspaces, 1, -1 do
    local workspace = self.workspaces[i]
    if not module.list_contains(active_workspaces, workspace) then
      table.remove(self.workspaces, i)
    end
  end

  wezterm.GLOBAL.workspace_history = self.workspaces
end

--- Add workspace to workspaces list (move to front if exists, add to front if new)
---@param workspace_name string The name of the workspace to add to workspaces list
function module:push_workspace(workspace_name)
  self:ensure_initialized()
  -- Remove workspace if it already exists in the list (linear search)
  for i = 1, #self.workspaces do
    wezterm.log_info('Index: ' .. i)
    if self.workspaces[i] == workspace_name then
      table.remove(self.workspaces, i)
      break
    end
  end

  table.insert(self.workspaces, 1, workspace_name)
  wezterm.GLOBAL.workspace_history = self.workspaces
end

--- Switch to workspace with tracking
---@param window wezterm.Window The current WezTerm window
---@param pane wezterm.Pane The current WezTerm pane
---@param workspace_name string The name of the workspace to switch to
---@param spawn_args table|nil Optional spawn arguments (e.g., { cwd = "/path" })
--- Performs the workspace switch and updates the workspaces list accordingly
--- If the workspace_name is the same as the current workspace, no action is taken
function module.switch_to_workspace(window, pane, workspace_name, spawn_args)
  wezterm.log_info 'Switching workspaces'
  local current_workspace = window:active_workspace()

  -- Early return if trying to switch to same workspace
  if current_workspace == workspace_name then
    return
  end

  -- Build switch action with optional spawn arguments
  local switch_action = { name = workspace_name }
  if spawn_args then
    switch_action.spawn = spawn_args
  end

  -- Perform the actual workspace switch
  window:perform_action(act.SwitchToWorkspace(switch_action), pane)

  module:push_workspace(workspace_name)
end

--- Switch to the last workspace (second element in MRU list)
---@param window wezterm.Window The current WezTerm window
---@param pane wezterm.Pane The current WezTerm pane
--- Retrieves the workspace at index 2 in the MRU list (the "last" workspace)
--- If there is no previous workspace or it's the same as current, no action is taken
--- This is the core function used by the LEADER L keybinding
function module.switch_to_last_workspace(window, pane)
  module:ensure_initialized()
  local current_workspace = window:active_workspace()

  -- Get the "last" workspace (second element in MRU list)
  local last_workspace = module.workspaces[2]

  -- No previous workspace exists or already at that workspace
  if not last_workspace or last_workspace == current_workspace then
    return
  end

  -- Switch to the last workspace using our tracked function
  module.switch_to_workspace(window, pane, last_workspace)
end

--- Workspace selector callback function. Use with wezterm.action_callback()
---@param window wezterm.Window The current WezTerm window
---@param pane wezterm.Pane The current WezTerm pane
--- Displays a fuzzy selector with:
--- 1. All active workspaces (prefixed with " ")
--- 2. All zoxide-managed directories (prefixed with " ")
--- When a workspace is selected, switches to it using MRU-tracked function
--- When a path is selected, creates a workspace named after the directory basename
--- Uses our wrapper functions to ensure MRU tracking is maintained
function module.workspace_selector_callback(window, pane)
  module:ensure_initialized()
  local choices = {}

  -- Add active workspaces
  for _, ws in ipairs(module.workspaces) do
    table.insert(choices, { label = ' ' .. ws, id = 'workspace:' .. ws })
  end

  -- Add zoxide paths
  local success, stdout, stderr = wezterm.run_child_process { 'zoxide', 'query', '--list' }
  if success then
    for path in stdout:gmatch '[^\r\n]+' do
      local label = path:gsub(wezterm.home_dir, '~')
      table.insert(choices, { label = ' ' .. label, id = 'path:' .. path })
    end
  elseif stderr then
    wezterm.log_error('zoxide error: ' .. stderr)
  end

  window:perform_action(
    act.InputSelector {
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id and not label then
          wezterm.log_info 'cancelled'
        else
          wezterm.log_info('id = ' .. id)
          wezterm.log_info('label = ' .. label)

          local workspace_type, identifier = id:match '([^:]+):(.+)'
          local workspace_name

          if workspace_type == 'workspace' then
            workspace_name = identifier
          elseif workspace_type == 'path' then
            workspace_name = identifier:match '([^/]+)$'
          else
            wezterm.log_error('Unknown ID format: ' .. id)
            return
          end

          -- Use our wrapper function instead of direct SwitchToWorkspace
          if workspace_type == 'workspace' then
            module.switch_to_workspace(inner_window, inner_pane, workspace_name)
          elseif workspace_type == 'path' then
            module.switch_to_workspace(inner_window, inner_pane, workspace_name, { cwd = identifier })
          end
        end
      end),
      title = 'Select Workspace',
      choices = choices,
      fuzzy = true,
      fuzzy_description = ' ',
    },
    pane
  )
end

--- Initialize workspace history lazily on first use (see ensure_initialized)
module.workspaces = nil

return module
