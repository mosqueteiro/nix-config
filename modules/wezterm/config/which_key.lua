--------------------------------------------------------------------------------
-- Which-Key Overlay
--------------------------------------------------------------------------------
local wezterm = require 'wezterm'
local act = wezterm.action

local module = {}

-- TODO: currently this doesn't get the key groups properly, everything gets assigned to [Default key], fix this

-- Helper function to format key combination
local function format_key_combo(key, mods)
  if not mods or mods == 'NONE' then
    return key
  end

  -- Replace modifier names with symbols for better readability
  local mod_symbols = {
    CTRL = 'Ctrl',
    SHIFT = 'Shift',
    ALT = 'Alt',
    SUPER = 'Super',
    CMD = 'Cmd',
    WIN = 'Win',
    LEADER = 'Leader',
  }

  local formatted_mods = mods
  for mod, symbol in pairs(mod_symbols) do
    formatted_mods = formatted_mods:gsub(mod, symbol)
  end

  -- Replace | with +
  formatted_mods = formatted_mods:gsub('|', '+')

  return formatted_mods .. ' + ' .. key
end

-- Helper function to format action for display
local function format_action(action_str)
  if not action_str then
    return 'Unknown Action'
  end

  -- Remove function calls and extract meaningful names
  local action_name = action_str:match 'act%.([^(]+)'
  if action_name then
    -- Handle some special cases
    if action_name == 'SplitVertical' then
      return 'Split Vertical'
    elseif action_name == 'SplitHorizontal' then
      return 'Split Horizontal'
    elseif action_name == 'ActivatePaneDirection' then
      local direction = action_str:match '"(.-)"'
      return 'Navigate Pane ' .. (direction or '')
    elseif action_name == 'AdjustPaneSize' then
      local direction, size = action_str:match "'([^'])',%s*(%d+)"
      return 'Resize Pane ' .. (direction or '') .. ' ' .. (size or '')
    elseif action_name == 'SpawnTab' then
      return 'New Tab'
    elseif action_name == 'CloseCurrentPane' then
      return 'Close Pane'
    elseif action_name == 'CloseCurrentTab' then
      return 'Close Tab'
    elseif action_name == 'ActivateTabRelative' then
      local offset = action_str:match '(%d+)'
      if offset == '1' then
        return 'Next Tab'
      else
        return 'Previous Tab'
      end
    end

    -- Convert camelCase to readable format
    action_name = action_name:gsub('(%u)', ' %1'):gsub('^%s+', '')
    return action_name:gsub('^%l', string.upper)
  end

  -- If it's a callback or complex action, try to extract something meaningful
  if action_str:match 'action_callback' then
    return 'Custom Action'
  elseif action_str:match 'ShowLauncherArgs' then
    return 'Show Launcher'
  elseif action_str:match 'InputSelector' then
    return 'Show Selector'
  end

  return action_str
end

-- Parse key bindings from wezterm show-keys --lua output
local function parse_key_bindings()
  -- local success, stdout, stderr = wezterm.run_child_process({ "env" })
  -- wezterm.log_info("Success: " .. tostring(success) .. " stdout: " .. stdout .. " stderr: " .. stderr)
  -- local success, stdout, stderr = wezterm.run_child_process({ "ls", "-l", wezterm.executable_dir })
  -- wezterm.log_info("Success: " .. tostring(success) .. " stdout: " .. stdout .. " stderr: " .. stderr)
  local success, stdout, stderr = wezterm.run_child_process { wezterm.executable_dir .. '/wezterm', 'show-keys', '--lua' }

  if not success then
    wezterm.log_error('Failed to get key bindings: ' .. (stderr or 'unknown error'))
    return {}
  end

  local choices = {}
  local current_section = 'Default Keys'

  -- Parse the output line by line
  for line in stdout:gmatch '[^\r\n]+' do
    -- Detect section headers
    if line:match '^Key Table:' then
      current_section = line:match 'Key Table:%s*(.+)'
    elseif line:match '{%s*key%s*=' then
      -- Parse key binding entries
      local key = line:match 'key%s*=%s*["\']([^"\']+)["\']'
      local mods = line:match 'mods%s*=%s*["\']([^"\']+)["\']'
      local action_str = line:match 'action%s*=%s*(.+)'

      if key and action_str then
        local key_combo = format_key_combo(key, mods)
        local action_desc = format_action(action_str)
        local section_prefix = string.format('[%s]', current_section)

        -- Format: "[section] key_combo          action_desc"
        local full_label = string.format('%-15s %-20s %s', section_prefix, key_combo, action_desc)

        table.insert(choices, {
          id = key_combo,
          label = full_label,
        })
      end
    end
  end

  return choices
end

--- Which-key callback function. Shows searchable overlay of all key bindings.
---@param window wezterm.Window The current window
---@param pane wezterm.Pane The current pane
function module.which_key_callback(window, pane)
  local choices = parse_key_bindings()

  if #choices == 0 then
    wezterm.log_info 'No key bindings found'
    return
  end

  -- Sort choices by section and then by key combo
  table.sort(choices, function(a, b)
    -- Extract section from label format "... [section_name]"
    local section_a = a.label:match '%[([^%]]+)%]%s*$' or ''
    local section_b = b.label:match '%[([^%]]+)%]%s*$' or ''

    if section_a ~= section_b then
      return section_a < section_b
    end
    return a.id < b.id
  end)

  window:perform_action(
    act.InputSelector {
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        -- Since this is just for display, we don't need to do anything
        -- when a selection is made. The overlay will close automatically.
        if not id and not label then
          wezterm.log_info 'Which-key cancelled'
        else
          wezterm.log_info('Key: ' .. (id or ''))
        end
      end),
      title = '🔑 Key Bindings',
      choices = choices,
      fuzzy = true,
      fuzzy_description = '🔍 Search key bindings...',
    },
    pane
  )
end

return module
