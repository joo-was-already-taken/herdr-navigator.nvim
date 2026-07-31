package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local config = require("herdr-navigator.config")
local validate = config.validate_opts

describe("validate_opts", function()
  describe("accepts valid opts", function()
    it("accepts an empty table", function()
      assert.has_no.errors(function()
        validate({})
      end)
    end)

    it("accepts nil opts (caller guard)", function()
      assert.has_no.errors(function()
        validate({})
      end)
    end)

    it("accepts a valid enabled function", function()
      assert.has_no.errors(function()
        validate({
          enabled = function()
            return true
          end,
        })
      end)
    end)

    it("accepts a full keys table", function()
      assert.has_no.errors(function()
        validate({
          keys = { left = "<C-h>", right = "<C-l>", up = "<C-k>", down = "<C-j>" },
        })
      end)
    end)

    it("accepts a partial keys table", function()
      assert.has_no.errors(function()
        validate({ keys = { left = "<C-h>" } })
      end)
    end)

    it("accepts empty-string key values (disables that binding)", function()
      assert.has_no.errors(function()
        validate({ keys = { left = "" } })
      end)
    end)

    it("accepts nil values for individual keys", function()
      assert.has_no.errors(function()
        validate({ keys = { left = nil, right = "<C-l>" } })
      end)
    end)
  end)

  describe("rejects invalid `enabled`", function()
    local bad_values = {
      { label = "boolean true", value = true },
      { label = "boolean false", value = false },
      { label = "string", value = "yes" },
      { label = "number", value = 1 },
      { label = "table", value = {} },
    }

    for _, case in ipairs(bad_values) do
      it("rejects enabled = " .. case.label, function()
        assert.has_error(function()
          validate({ enabled = case.value })
        end, nil)
      end)
    end

    it("error message mentions 'enabled' and the wrong type", function()
      local ok, err = pcall(validate, { enabled = 42 })
      assert.is_false(ok)
      assert.matches("`enabled`", err)
      assert.matches("number", err)
    end)
  end)

  describe("rejects invalid `keys` type", function()
    it("rejects keys = string", function()
      local ok, err = pcall(validate, { keys = "nope" })
      assert.is_false(ok)
      assert.matches("`keys`", err)
      assert.matches("string", err)
    end)

    it("rejects keys = number", function()
      local ok, _ = pcall(validate, { keys = 42 })
      assert.is_false(ok)
    end)

    it("rejects keys = boolean", function()
      local ok, _ = pcall(validate, { keys = true })
      assert.is_false(ok)
    end)
  end)

  describe("rejects non-string direction values", function()
    local directions = config.VALID_DIRECTIONS

    for _, dir in ipairs(directions) do
      it("rejects keys." .. dir .. " = number", function()
        local ok, err = pcall(validate, { keys = { [dir] = 1 } })
        assert.is_false(ok)
        assert.matches("`keys%." .. dir .. "`", err)
        assert.matches("number", err)
      end)

      it("rejects keys." .. dir .. " = boolean", function()
        local ok, _ = pcall(validate, { keys = { [dir] = false } })
        assert.is_false(ok)
      end)

      it("rejects keys." .. dir .. " = table", function()
        local ok, _ = pcall(validate, { keys = { [dir] = {} } })
        assert.is_false(ok)
      end)
    end
  end)

  describe("rejects unknown fields inside `keys`", function()
    it("rejects an unknown direction name", function()
      local ok, err = pcall(validate, { keys = { horizontal = "<C-h>" } })
      assert.is_false(ok)
      assert.matches("unknown field", err)
      assert.matches("horizontal", err)
    end)

    it("rejects a typo in direction name", function()
      local ok, err = pcall(validate, { keys = { lft = "<C-h>" } })
      assert.is_false(ok)
      assert.matches("lft", err)
    end)
  end)

  it("always prefixes errors with the plugin name", function()
    local ok, err = pcall(validate, { enabled = "bad" })
    assert.is_false(ok)
    assert.matches("herdr%-navigator%.nvim", err)
  end)
end)
