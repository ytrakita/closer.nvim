local api = vim.api
local vb = vim.b

local M = {}

local function get_char(row, col)
  return api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, {})[1]
end

local function get_neigh_chars()
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local right = get_char(row, col)
  local left = get_char(row, math.max(col - 1, 0))
  return left, right
end

function M.close(input)
  local left, right = get_neigh_chars()
  if left == '\\' or (input == "'" and left:match('[%w]')) then
    return input
  elseif vb.closer_pair_tbl[input] == input and right == input then
    return '<C-G>U<Right>'
  else
    return ('%s%s<C-G>U<Left>'):format(input, vb.closer_pair_tbl[input])
  end
end

function M.skip(input)
  local _, right = get_neigh_chars()
  if right == input then
    return '<C-G>U<Right>'
  else
    return input
  end
end

function M.bs()
  local left, right = get_neigh_chars()
  if right == vb.closer_pair_tbl[left] then
    return '<C-G>U<Right><BS><BS>'
  else
    return '<BS>'
  end
end

function M.cr()
  local left, right = get_neigh_chars()
  if left:match('[%(%{%[]') and right == vb.closer_pair_tbl[left] then
    return '<CR><C-O>O'
  else
    return '<CR>'
  end
end

function M.space()
  local left, right = get_neigh_chars()
  if left:match('[%(%{%[]') and right == vb.closer_pair_tbl[left] then
    return '  <C-G>U<Left>'
  else
    return ' '
  end
end

return M
