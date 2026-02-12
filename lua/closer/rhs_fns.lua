local config = require 'closer.config'

local api = vim.api
local b = vim.b

local M = {}

---@param mode 'c'|'i'
---@return string
---@return string
local function get_adj_chars(mode)
  local line, lpos
  if mode == 'i' then
    line = api.nvim_get_current_line()
    lpos = api.nvim_win_get_cursor(0)[2] + 1
  else
    line = vim.fn.getcmdline()
    lpos = vim.fn.getcmdpos()
  end
  line = '_' .. line
  local rpos = lpos + 1
  return line:sub(lpos, lpos), line:sub(rpos, rpos)
end

---@param mode 'c'|'i'
---@return string
local function cont_undo_block(mode)
  return mode == 'i' and '<C-G>U' or ''
end

---@param mode 'c'|'i'
---@return closer.Pairs
local function get_pairs(mode)
  return mode == 'i' and b.closer_pairs or config.get 'cmdline'
end

---@param input string
---@param mode 'c'|'i'
---@return string
function M.close(input, mode)
  local left, right = get_adj_chars(mode)
  local pairs_ = get_pairs(mode)
  if left == '\\' or (input == "'" and left:match '[%w]') then
    return input
  elseif pairs_[input] == input and right == input then
    return cont_undo_block(mode) .. '<Right>'
  else
    return input .. cont_undo_block(mode) .. pairs_[input] .. '<Left>'
  end
end

---@param input string
---@param mode 'c'|'i'
---@return string
function M.skip(input, mode)
  local _, right = get_adj_chars(mode)
  if right == input then
    return cont_undo_block(mode) .. '<Right>'
  else
    return input
  end
end

---@param mode 'c'|'i'
---@return string
function M.bs(mode)
  local left, right = get_adj_chars(mode)
  if right == get_pairs(mode)[left] then
    return cont_undo_block(mode) .. '<BS><Del>'
  else
    return '<BS>'
  end
end

M.c_h = M.bs

---@param mode 'c'|'i'
---@return string
function M.c_w(mode)
  local left, right = get_adj_chars(mode)
  if right == get_pairs(mode)[left] then
    return cont_undo_block(mode) .. '<C-W><Del>'
  else
    return '<C-W>'
  end
end

---@param mode 'c'|'i'
---@return string
function M.cr(mode)
  if mode == 'c' then return '<CR>' end
  local left, right = get_adj_chars 'i'
  if left:match '[%(%{%[]' and right == get_pairs(mode)[left] then
    return '<CR><C-O>O'
  else
    return '<CR>'
  end
end

---@param mode 'c'|'i'
---@return string
function M.space(mode)
  local left, right = get_adj_chars(mode)
  if left:match '[%(%{%[]' and right == get_pairs(mode)[left] then
    return '  ' .. cont_undo_block(mode) .. '<Left>'
  else
    return ' '
  end
end

return M
