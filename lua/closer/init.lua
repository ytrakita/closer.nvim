local rhs_fns = require 'closer.rhs_fns'

local vim = vim
local api = vim.api
local map = vim.keymap.set

local M = {}

local default_pair_tbl = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['`'] = '`',
  ['"'] = '"',
  ["'"] = "'",
}

local function set_pair_keymap(lhs, fn)
  local rhs = function() return rhs_fns[fn](lhs) end
  map('i', lhs, rhs, { expr = true, buffer = true })
end

local function set_plug_keymap(key)
  local lhs = ('<Plug>(closer_%s)'):format(key)
  local rhs = function() return rhs_fns[key]() end
  map('i', lhs, rhs, { expr = true })
end

local function on_bufenter(is_force)
  if not is_force and vim.closer_pair_tbl then return end

  vim.b.closer_pair_tbl = vim.b.closer_pair_tbl or default_pair_tbl

  for left, right in pairs(vim.b.closer_pair_tbl) do
    set_pair_keymap(left, 'close')

    if left ~= right then
      set_pair_keymap(right, 'skip')
    end
  end
end

-- opts keys: pairs, ft
function M.setup(opts)
  opts = opts or {}
  opts.ft = opts.ft or {}

  default_pair_tbl = opts.pairs or default_pair_tbl

  local group_id = api.nvim_create_augroup('closer', { clear = true })
  api.nvim_create_autocmd({ 'BufEnter' }, {
    group = group_id,
    pattern = '*',
    callback = on_bufenter,
  })

  for ft, pair_tbl in pairs(opts.ft) do
    api.nvim_create_autocmd({ 'FileType' }, {
      group = group_id,
      pattern = ft,
      callback = function()
        vim.b.closer_pair_tbl = pair_tbl
        on_bufenter(true)
      end,
    })
  end

  on_bufenter()

  for _, key in ipairs({ 'bs', 'cr', 'space' }) do
    set_plug_keymap(key)
  end
end

return M
