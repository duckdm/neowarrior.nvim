local util = require 'neowarrior.util'

---@class Line
---@field line_no number
---@field text string
---@field meta_text string
---@field meta_data table
---@field colors table[]
---@field current_col number
---@field last_col number
---@field new fun(self: Line, line_no: number): Line
---@field add fun(self: Line, block: table): Line
local Line = {}

--- Create a new Line
---@param line_no number
function Line:new(line_no)
  local line = {}
  setmetatable(line, self)
  self.__index = self

  line.line_no = line_no
  line.text = ''
  line.meta_text = ''
  line.meta_data = nil
  line.colors = {}
  line.current_col = 0
  line.last_col = 0

  return util.copy(line)
end

--- Add text to line
---@param block table
---@return Line
function Line:add(block)

  if block.text then
    if block.seperator then
      self.text = self.text .. block.seperator .. block.text
    else
      self.text = self.text .. block.text
    end
  end

  if block.meta then
    self.meta_data = block.meta
    -- self.meta_text = self.meta_text .. " "
    -- for key, value in pairs(block.meta) do
    --   self.meta_text = self.meta_text .. "{{{" .. key .. value .. "}}}"
    -- end
  end

  if self.current_col > 0 then
    self.last_col = self.current_col
  else
    self.last_col = 0
  end
  self.current_col = string.len(self.text)

  if block.color then
    table.insert(self.colors, {
      group = block.color,
      from = self.last_col,
      to = self.current_col,
      line = self.line_no,
    })
  end

  return self
end

return Line
