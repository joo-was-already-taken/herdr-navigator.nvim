local M = {}

M.VALID_DIRECTIONS = { "left", "right", "up", "down" }

--- @param opts herdr_navigator.Config
function M.validate_opts(opts)
  local prefix = "herdr-navigator.nvim setup(): "

  if opts.enabled ~= nil and type(opts.enabled) ~= "function" then
    error(prefix .. "`enabled` must be a function, got " .. type(opts.enabled))
  end

  if opts.keys ~= nil then
    if type(opts.keys) ~= "table" then
      error(prefix .. "`keys` must be a table, got " .. type(opts.keys))
    end

    for _, dir in ipairs(M.VALID_DIRECTIONS) do
      local val = opts.keys[dir]
      if val ~= nil and type(val) ~= "string" then
        error(prefix .. "`keys." .. dir .. "` must be a string, got " .. type(val))
      end
    end

    for key in pairs(opts.keys) do
      local valid = false
      for _, dir in ipairs(M.VALID_DIRECTIONS) do
        if key == dir then
          valid = true
          break
        end
      end
      if not valid then
        error(prefix .. "`keys` has unknown field `" .. tostring(key) .. "`")
      end
    end
  end
end

return M
