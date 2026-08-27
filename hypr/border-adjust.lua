-- Adjust window border size based on number of windows on current workspace
-- Borders appear only when there are >1 windows on the workspace
-- Runs once on Hyprland startup

local M = {}

local function exec(cmd)
  local f = io.popen(cmd)
  local result = f:read("*a")
  f:close()
  return result
end

local function get_active_workspace_id()
  local output = exec("hyprctl activeworkspace -j")
  if not output or output == "" then return nil end
  -- Parse JSON manually: find "id": NUMBER pattern
  local id = output:match('"id":%s*(%d+)')
  return id and tonumber(id)
end

local function get_window_count_on_workspace(workspace_id)
  if not workspace_id then return 0 end
  local output = exec(string.format(
    "hyprctl clients -j | jq -r '.[] | select(.workspace.id == %d)' | wc -l", workspace_id
  ))
  if not output then return 0 end
  local count = tonumber(output:match("%s*(%d+)%s*$"))
  return count or 0
end

local function set_border_size(size)
  exec("hyprctl keyword general:border_size " .. tostring(size))
end

local function adjust_border()
  local ws_id = get_active_workspace_id()
  if not ws_id then return end

  local count = get_window_count_on_workspace(ws_id)

  if count and count <= 1 then
    set_border_size(0)
  else
    set_border_size(1)
  end
end

-- Run once on script load
adjust_border()

-- Export function for manual triggering (can be called from keybinding)
M.adjust_border = adjust_border

return M