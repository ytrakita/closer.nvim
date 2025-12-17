local rhs_fns = require 'closer.rhs_fns'

local api = vim.api
local km = vim.keymap
local b = vim.b

local M = {}

local function set_pair_keymap(lhs, fn)
  local rhs = function() return rhs_fns[fn](lhs) end
  km.set('i', lhs, rhs, { expr = true, buffer = true })
end

local function on_bufenter(is_force)
  if not is_force and b.closer_pairs then return end

  b.closer_pairs = b.closer_pairs
    or M.config.ft[api.nvim_get_option_value('filetype', { buf = 0 })]
    or M.config.pairs

  for left, right in pairs(b.closer_pairs) do
    set_pair_keymap(left, 'close')
    if left ~= right then
      set_pair_keymap(right, 'skip')
    end
  end
end

M.config = {
  pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['`'] = '`',
    ['"'] = '"',
    ["'"] = "'",
  },
  maps = {
    bs = true,
    c_h = true,
    cr = true,
    space = true,
  },
}

-- opts keys: pairs, ft, maps
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  local group_id = api.nvim_create_augroup('closer', { clear = true })
  api.nvim_create_autocmd('BufEnter', {
    group = group_id,
    pattern = '*',
    callback = on_bufenter,
  })
  for ft, pairs in pairs(opts.ft) do
    api.nvim_create_autocmd('FileType', {
      group = group_id,
      pattern = ft,
      callback = function()
        b.closer_pairs = pairs
        on_bufenter(true)
      end,
    })
  end

  vim.cmd.filetype 'detect'
  on_bufenter(true)

  for key, lhs in pairs({ bs = '<BS>', cr = '<CR>', space = ' ' }) do
    if M.config.maps[key] then
      km.set('i', lhs, rhs_fns[key], { expr = true })
    end
  end

  if M.config.maps.c_h then
    km.set('i', '<C-H>', rhs_fns.bs, { expr = true })
  end
end

return M
