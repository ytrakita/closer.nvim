local api = vim.api
local km = vim.keymap
local b = vim.b

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

---@param mode 'c'|'i'
---@param lhs string
---@param fn 'close'|'skip'
local function set_pair_keymap(mode, lhs, fn)
  local rhs = function() return require 'closer.rhs_fns'[fn](lhs, mode) end
  km.set(mode, lhs, rhs, { expr = true, buffer = mode == 'i' })
end

---@param mode 'c'|'i'
---@param pairs_ closer.Pairs|false
local function set_pair_keymaps(mode, pairs_)
  if not pairs_ then return end
  for left, right in pairs(pairs_) do
    set_pair_keymap(mode, left, 'close')
    if left ~= right then
      set_pair_keymap(mode, right, 'skip')
    end
  end
end

function M.buf_setup()
  if b.closer_pairs then return end
  local ft = api.nvim_get_option_value('filetype', { buf = 0 })
  b.closer_pairs = config.ft[ft] or config.pairs
  set_pair_keymaps('i', b.closer_pairs)
end

function M.buf_refresh()
  if b.closer_pairs then
    for left, right in pairs(b.closer_pairs) do
      km.del('i', left, { buffer = true })
      if left ~= right then
        km.del('i', right, { buffer = true })
      end
    end
    b.closer_pairs = nil
  end
  M.buf_setup()
end

local function init()
  M.buf_setup()
  set_pair_keymaps('c', config.cmdline)

  local map = {
    bs = '<BS>', c_h = '<C-H>', c_w = '<C-W>', cr = '<CR>', space = ' ',
  }

  for _, mode in ipairs { 'i', config.cmdline and 'c' } do
    for fname, lhs in pairs(map) do
      if config.maps[fname] then
        local fn = function() return require 'closer.rhs_fns'[fname](mode) end
        km.set(mode, lhs, fn, { expr = true })
      end
    end
  end
end

---@param opts closer.Config?
function M.setup(opts)
  config = vim.tbl_deep_extend('force', default, opts or {})
  if config.cmdline == true then
    config.cmdline = config.pairs
  end

  local group = api.nvim_create_augroup('closer', { clear = true })
  local enter = { group = group, pattern = '*', callback = M.buf_setup }
  api.nvim_create_autocmd('BufEnter', enter)
  for ft in pairs(config.ft) do
    local filetype = { group = group, pattern = ft, callback = M.buf_refresh }
    api.nvim_create_autocmd('FileType', filetype)
  end

  init()
end

return M
