--- Component class. A collection of lines.
---@class Component
---
---@field line_count number
---@field lines Line[]
---@field colors table
---@field new fun(self: Component, line_count: number): Component
---@field reset fun(self: Component): Component
---@field add fun(self: Component, line: Line): Component
---@field add_raw fun(self: Component, string: string): Line
---@field pop fun(self: Component): Line
---@field get fun(self: Component): Line[]
---@field print fun(self: Component, buffer: Buffer): Component
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

  if type(lines) ~= 'table' then
    lines = { lines }
  end

  for _, line in ipairs(lines) do
    table.insert(self.lines, line.text .. line.meta_text)
    self.line_count = self.line_count + 1

    for _, color in ipairs(line.colors) do
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
  vim.api.nvim_buf_set_lines(buffer.id, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(buffer.id, 0, -1, false, self.lines)
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
