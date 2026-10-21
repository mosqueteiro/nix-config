--------------------------------------------------------------------------------
-- Host specific module
--
-- This module contains code for host specific configuration and fixes
--
--------------------------------------------------------------------------------

local wezterm = require 'wezterm'

local M = {}
M.config = {}

local hostname = io.popen('hostname'):read('*a'):gsub('%s+', '')
if hostname == 'frameworkDesktop' then
  -- M.config.front_end = 'WebGpu'
  M.config.enable_wayland = false
end
-- use this to test: `for k, v in pairs(window:effective_config()) do if k:match("front") then print(k, v) end end`

return M
