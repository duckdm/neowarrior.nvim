---@class Line
---@field line_no number
---@field text string
---@field meta_text string
---@field colors table
---@field current_col number
---@field last_col number
---@field ns_name string
---@field new fun(self: Line): Line
---@field col fun(self: Line, block: table): Line
local Line = {}

--- Create a new Line
function Line:new()
  local line = {}
  setmetatable(line, self)
  self.__index = self

  line.text = ''
  line.virt_text = ''
  line.meta_text = ''
  line.colors = {}
  line.ns_name = "trambampolin"
  line.pos = "overlay"
  line.col_num = 0
  line.strict_col_num = 0
  line.current_col = 0
  line.last_col = 0

  return line
end

--- Add text to line
---@param block table
---@return Line
function Line:col(block)

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
    self.meta_text = self.meta_text .. " "
    for key, value in pairs(block.meta) do
      self.meta_text = self.meta_text .. "{{{" .. key .. value .. "}}}"
    end
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
