local M = {}

---@alias closer.Pairs table<string, string>
---@alias closer.Mapfn 'bs'|'c_h'|'c_w'|'cr'|'space'

---@class closer.Config
---@field pairs? closer.Pairs
---@field ft? table<string, closer.Pairs>
---@field maps? table<closer.Mapfn, boolean>
---@field cmdline? boolean|closer.Pairs
local config

---@type closer.Config
local default = {
  pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['`'] = '`',
    ['"'] = '"',
    ["'"] = "'",
  },
  ft = {},
  maps = {
    bs = true,
    c_h = true,
    c_w = true,
    cr = true,
    space = true,
  },
  cmdline = true,
}

---@param opts? closer.Config
function M.setup(opts)
  config = vim.tbl_deep_extend('force', default, opts or {})
  if config.cmdline == true then
    config.cmdline = config.pairs
  end
end

---@param key string
---@return any
function M.get(key)
  return config[key]
end

return M
