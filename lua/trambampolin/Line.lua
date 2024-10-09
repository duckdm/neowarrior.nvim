---@class Line
---@field text string
---@field virt_text string
---@field meta_text string
---@field meta_data table
---@field colors table
---@field ns_name string
---@field pos string
---@field col_num number
---@field strict_col_num number
---@field current_col number
---@field last_col number
---@field line_no number
---@field col fun(self: Line, block: table):Line
---@field new fun(self: Line):Line
local Line = {}

--- Create a new Line
function Line:new()
  local line = {}
  setmetatable(line, self)
  self.__index = self

  line.text = ''
  line.virt_text = ''
  line.meta_text = ''
  line.meta_data = nil
  line.colors = {}
  line.ns_name = "trambampolin"
  line.pos = "overlay"
  line.col_num = 0
  line.strict_col_num = 0
  line.current_col = 0
  line.last_col = 0
  line.line_no = 0

  return line
end

--- Add text to line
---@param block table
---@return Line
function Line:col(block)

  self.line_no = block.line_no or nil

  if block.text then
    if block.seperator then
      self.text = self.text .. block.seperator .. block.text
    else
      self.text = self.text .. block.text
    end
  end

  if block.virt_text then
    self.virt_text = self.virt_text .. block.virt_text
  end

  if block.pos then self.pos = block.pos end
  if block.col then self.col_num = block.col end
  if block.strict_col then self.strict_col_num = block.strict_col end
  if block.ns_name then self.ns_name = block.ns_name end

  if block.meta then
    self.meta_data = block.meta
    -- self.meta_text = self.meta_text .. " "
    -- for key, value in pairs(block.meta) do
    --   self.meta_text = self.meta_text .. "{{{" .. key .. value .. "}}}"
    -- end
  end

  if (not block.virt_text) and self.current_col > 0 then
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
      line = nil,
    })

  end

  return self
end

return Line
