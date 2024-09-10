local Util = require('neowarrior.util')

---@class Buffer
---@field public id number
local Buffer = {}

--- Constructor
---@param arg table: { listed: boolean, scratch: boolean }
---@return Buffer
function Buffer:new(arg)
  local buffer = {}
  setmetatable(buffer, self)
  self.__index = self

  buffer.listed = arg.listed or false
  buffer.scratch = arg.scratch or true
  buffer.id = vim.api.nvim_create_buf(buffer.listed, buffer.scratch)
  buffer.cursor = nil

  return buffer
end

--- Set buffer name
---@param name string
---return Buffer
function Buffer:set_name(name)
  vim.api.nvim_buf_set_name(self.id, name)
  return self
end

--- Set buffer option
---@param key string
---@param value any
---@param opt table
---@return Buffer
function Buffer:option(key, value, opt)
  vim.api.nvim_set_option_value(key, value, opt)
  return self
end

--- Lock buffer
---@return Buffer
function Buffer:lock()
  self:option("modifiable", false, { buf = self.id })
  return self
end

--- Unlock buffer
---@return Buffer
function Buffer:unlock()
  self:option("modifiable", true, { buf = self.id })
  return self
end

--- Get meta data from current line
---@param key string
---@return string|nil
function Buffer:get_meta_data(key)
  local line = vim.api.nvim_get_current_line()
  local pattern = "{{{" .. key .. ".-}}}"
  local value = nil
  for id in string.gmatch(line, pattern) do
    value = string.gsub(string.gsub(id, "{{{" .. key, ""), "}}}", "")
  end
  return value
end

--- Get cursor
---@return integer[]
function Buffer:get_cursor()
  local win = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_cursor(win)
end

--- Save cursor
---@return integer[]
function Buffer:save_cursor()
  self.cursor = self:get_cursor()
  return self.cursor
end

--- Restore saved cursor
---@return Buffer|nil
function Buffer:restore_cursor()

  if not self.cursor then
    return nil
  end

  local win = vim.api.nvim_get_current_win()
  local total_lines = vim.api.nvim_buf_line_count(self.id)
  local target_line = self.cursor[1]

  if target_line >= total_lines then
    vim.api.nvim_win_set_cursor(win, { total_lines, 0 })
  else
    vim.api.nvim_win_set_cursor(win, self.cursor)
  end

  self.cursor = nil

  return self
end

--- Set buffer virt text
---@param text string
---@param hl_group string
---@param ns_name string
---@param o table Extend options
---@return number
function Buffer:virt_text(text, hl_group, ns_name, o)

  local line_no = o.line_no or self:get_cursor()[1]
  if o.line_no then
    o.line_no = nil
  end
  local col_num = o.col_num or 0
  local api = vim.api
  local ns_id = api.nvim_create_namespace(ns_name)
  local opts = vim.tbl_deep_extend('force', {
    end_line = line_no + 1,
    id = 1,
    virt_text_pos = 'overlay',
    virt_text = { { text, hl_group } },
  }, o)

  return api.nvim_buf_set_extmark(self.id, ns_id, line_no, col_num, opts)
end

--- Create line
---@param ln number Current line count
---@param blocks table
---@return table { string, table }
Buffer.create_line = function(ln, blocks)
  local b = 0
  local bf = 0
  local str = ""
  local meta_str = ""
  local colors = {}

  for _, block in ipairs(blocks) do
    if not block.disable then
      if block.text then
        if block.seperator then
          str = str .. block.seperator .. block.text
        else
          str = str .. block.text
        end
      end

      if block.meta then
        meta_str = meta_str .. " "
        for key, value in pairs(block.meta) do
          meta_str = meta_str .. "{{{" .. key .. value .. "}}}"
        end
      end

      if b > 0 then
        bf = b - 1
      else
        bf = 0
      end
      b = string.len(str)

      if block.color then
        table.insert(colors, {
          group = block.color,
          from = bf,
          to = b,
          line = ln,
        })
      end
    end
  end

  return { str .. meta_str, colors }
end

Buffer.apply_colors = function(colors, cta)
  for _, c in ipairs(cta) do
    table.insert(colors, c)
  end
end

return Buffer
