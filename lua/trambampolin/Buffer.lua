---@class Buffer
---@field public id number
---@field public listed boolean
---@field public scratch boolean
---@field public cursor integer[]|nil
---@field public name string|nil
---@field public set_name fun(self: Buffer, name: string): Buffer
---@field public process_lines fun(self: Buffer, up_lines: Line[], from: number): table
---@field public print fun(self: Buffer, lines: Line[], from: number): Buffer
---@field public option fun(self: Buffer, key: string, value: any, opt: table): Buffer
---@field public lock fun(self: Buffer): Buffer
---@field public unlock fun(self: Buffer): Buffer
---@field public get_meta_data fun(self: Buffer, key: string): string|nil
---@field public get_cursor fun(self: Buffer): integer[]
---@field public save_cursor fun(self: Buffer): integer[]
---@field public restore_cursor fun(self: Buffer): Buffer|nil
---@field public virt_text fun(self: Buffer, text: string, hl_group: string, ns_name: string, o: table): number
---@field public create_line fun(ln: number, blocks: table): table
---@field public apply_colors fun(colors: table, cta: table): nil
---@field public keymap fun(self: Buffer, mode: string|table, key: string, action: string|function, opts: table): Buffer
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
  buffer.name = nil

  return buffer
end

--- Set buffer keymap
---@param mode string|table
---@param key string
---@param action string|function
---@param opts? table|nil
function Buffer:keymap(mode, key, action, opts)
  opts = opts or {}
  opts.buffer = self.id
  vim.keymap.set(mode, key, action, opts)

  return self
end

--- Set buffer name
---@param name string
---return Buffer
function Buffer:set_name(name)
  self.name = name
  vim.api.nvim_buf_set_name(self.id, name)
  return self
end

--- Get buffer lines
---@return string[]
function Buffer:get_lines()
  return vim.api.nvim_buf_get_lines(self.id, 0, -1, false)
end

--- Process lines
---@param up_lines Line[]
---@param from number
---@return string[][]
function Buffer:process_lines(up_lines, from)

  local lines = {}
  local virt_lines = {}
  local colors = {}
  local line_no = from
  local last_line_len = 0

  for _, line in ipairs(up_lines) do

    if line.text and line.text ~= "" then

      local text = line.text
      if text == "__NL__" then text = "" end

      table.insert(lines, text)
      last_line_len = string.len(text)

      if line.colors then
        for _, c in ipairs(line.colors) do
          table.insert(colors, vim.tbl_extend('force', c, { line = line.line_no or line_no }))
        end
      end

      line_no = line_no + 1

    elseif line.virt_text and line.virt_text ~= "" then

      if line.virt_text then
        local virt_line_no = line.line_no or line_no
        if virt_line_no <= 0 then
          virt_line_no = 1
        end
        virt_line_no = virt_line_no - 1
        local col_num = line.col_num or 0
        if col_num > last_line_len then
          col_num = last_line_len
        end
        table.insert(virt_lines, {
          text = line.virt_text,
          hl_group = line.colors[1].group,
          ns_name = line.ns_name or "trambampolin",
          line_no = virt_line_no,
          virt_text_pos = line.pos or "overlay",
          col_num = col_num,
          strict_col_num = line.strict_col_num or nil,
        })
      end

    end

  end

  return { lines, virt_lines, colors }
end

--- Print buffer
---@param up_lines Line[] Unprocess lines
---@param from number
---@return Buffer
function Buffer:print(up_lines, from)

  local lines, virt_lines, colors = table.unpack(self:process_lines(up_lines, from))

  self:unlock()

  vim.api.nvim_buf_set_lines(self.id, from, -1, false, {})
  vim.api.nvim_buf_set_lines(self.id, from, -1, false, lines)

  for _, color in ipairs(colors) do
    if color and color.line and color.group and color.from and color.to then
      vim.api.nvim_buf_add_highlight(
        self.id,
        -1,
        color.group,
        color.line + from,
        color.from,
        color.to
      )
    end
  end

  if #virt_lines > 0 then
    for _, virt_line in ipairs(virt_lines) do
      self:virt_text(
        virt_line.text,
        virt_line.hl_group,
        "trambampolin",
        {
          line_no = virt_line.line_no,
          end_line = virt_line.line_no + 1,
          virt_text_pos = virt_line.virt_text_pos,
          ns_name = virt_line.ns_name,
          col_num = virt_line.col_num or 0,
          strict_col_num = virt_line.strict_col_num or nil,
        }
      )
    end
  end

  self:lock()

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
  return _Neowarrior.current_page.tram:get_line_meta_data(key)
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

function Buffer:set_cursor(line, col)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(win, { line, col })
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

  local line_no = o.line_no or 0
  local col_num = o.col_num or 0
  local ns_id = vim.api.nvim_create_namespace(ns_name)
  local default_text_post = o.strict_col_num and "inline" or "overlay"
  local opts = {
    end_line = o.end_line or (line_no + 1),
    virt_text_pos = o.virt_text_pos or default_text_post,
    virt_text = { { text, hl_group } },
  }

  if o.strict_col_num > 0 then
    opts.virt_text_win_col = o.strict_col_num
  end

  return vim.api.nvim_buf_set_extmark(self.id, ns_id, line_no, col_num, opts)
end

Buffer.apply_colors = function(colors, cta)
  for _, c in ipairs(cta) do
    table.insert(colors, c)
  end
end

return Buffer

