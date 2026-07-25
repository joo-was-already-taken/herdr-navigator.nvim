local M = {}

--- @class herdr_navigator.Config
--- @field enabled? fun(): boolean
--- @field keys? herdr_navigation.Keys

--- @class herdr_navigation.Keys
--- @field left? string
--- @field right? string
--- @field up? string
--- @field down? string

--- @type herdr_navigator.Config
local default_config = {
  enabled = function() return true end,
  keys = {
    left = "<C-h>",
    right = "<C-l>",
    up = "<C-k>",
    down = "<C-j>",
  },
}

--- @type herdr_navigator.Config | nil
M.config = nil

--- @param opts herdr_navigator.Config
local function update_config(opts)
  if opts.enabled == nil then
    M.config.enabled = default_config.enabled
  else
    M.config.enabled = opts.enabled
  end

  if opts.keys == nil or next(opts.keys) == nil then
    M.config.keys = vim.deepcopy(default_config.keys)
  else
    for direction, default_keys in pairs(default_config.keys) do
      M.config.keys[direction] = opts.keys[direction] or default_keys
    end
  end
end

--- @param direction "left" | "right" | "up" | "down"
function M.navigate(direction)
  local wincmds = {
    left = "h",
    right = "l",
    up = "k",
    down = "j",
  }

  if not M.config.enabled() then
    vim.cmd.wincmd(wincmds[direction])
    return
  end

  local win = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(wincmds[direction])
  local new_win = vim.api.nvim_get_current_win()

  if win == new_win then
    local cmd = { "herdr", "pane", "focus", "--direction", direction, "--current" }
    vim.fn.jobstart(cmd)
  end
end

--- @return string
function M.version()
  return require("herdr-navigator.version").version
end

--- @param opts? herdr_navigator.Config
function M.setup(opts)
  M.config = vim.deepcopy(default_config)

  if opts ~= nil and next(opts) ~= nil then
    update_config(opts)
  end

  for direction, key in pairs(M.config.keys) do
    if key and key ~= "" then
      vim.keymap.set({ "n", "t" }, key, function()
        M.navigate(direction)
      end, { silent = true })
    end
  end
end

return M
