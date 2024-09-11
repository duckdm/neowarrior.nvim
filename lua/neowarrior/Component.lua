--- Component class. A collection of lines.
---@class Component
---
---@field line_count number
---@field lines Line[]
---@field colors table
---@field type string
---@field new fun(self: Component, line_count: number): Component
---@field reset fun(self: Component): Component
---@field add fun(self: Component, line: Line): Component
---@field add_raw fun(self: Component, string: string): Line
---@field pop fun(self: Component): Line
---@field get fun(self: Component): Line[]
---@field print fun(self: Component, buffer: Buffer): Component
---@field debug fun(self: Component): Component
local Component = {}

--- Create new component
---@param line_count number
---@return Component
function Component:new(line_count)
    local component = {}
    setmetatable(component, self)
    self.__index = self

    self.line_count = line_count
    self.lines = {}
    self.colors = {}
    self.type = 'Component'

    return component
end

--- Reset component
---@return Component
function Component:reset()
  self.lines = {}
  self.colors = {}
  self.line_count = 0

  return self
end

--- Add line to page
---@param lines Line|Line[]
---@return Component
function Component:add(lines)

  for _, line in ipairs(lines) do
    local text = line.text or ''
    local meta = line.meta_text or ''
    local colors = line.colors or {}
    table.insert(self.lines, text .. meta)
    self.line_count = self.line_count + 1

    for _, color in ipairs(colors) do
      table.insert(self.colors, color)
    end
  end

  return self
end

--- Add raw string to page
---@param string string
---@return Component
function Component:add_raw(string)
  table.insert(self.lines, string)
  self.line_count = self.line_count + 1
  return self
end

--- Add empty line to page
---@return Component
function Component:nl()
  table.insert(self.lines, '')
  self.line_count = self.line_count + 1

  return self
end

--- Print component
---@param buffer Buffer
---@return Component
function Component:print(buffer)

  buffer:unlock()
  vim.api.nvim_buf_set_lines(buffer.id, self.line_count, -1, false, {})
  vim.api.nvim_buf_set_lines(buffer.id, self.line_count, -1, false, self.lines)
  for _, color in ipairs(self.colors) do
    if color and color.line and color.group and color.from and color.to then
      vim.api.nvim_buf_add_highlight(buffer.id, -1, color.group, color.line, color.from, color.to)
    end
  end
  buffer:lock()

  self:reset()

  return self
end

--- Get line count
---@return number
function Component:get_line_count()
  return self.line_count
end

--- Pop line
---@return Line
function Component:pop()
  local line = table.remove(self.lines)
  self.line_count = self.line_count - 1
  return line
end

--- Get lines
---@return Line[]
function Component:get()
  return self.lines
end

--- Debug component and print to console
---@return Component
function Component:debug()
  print('Component:')
  print('  line_count: ' .. self.line_count)
  print('  lines:')
  for _, line in ipairs(self.lines) do
    print('    ' .. line)
  end
  print('  colors:')
  for _, color in ipairs(self.colors) do
    print('    ' .. vim.inspect(color))
  end

  return self
end

return Component
