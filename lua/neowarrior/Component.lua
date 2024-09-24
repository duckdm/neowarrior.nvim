--- Component class. A collection of lines.
---@class Component
---
---@field line_count number
---@field lines Line[]
---@field text string[]
---@field colors table[]
---@field type string
---@field start_at number
---@field new fun(self: Component): Component
---@field from fun(self: Component, line_no: number): Component
---@field reset fun(self: Component): Component
---@field add fun(self: Component, lines: Line[]): Component
---@field add_raw fun(self: Component, string: string|number): Component
---@field nl fun(self: Component): Component
---@field print fun(self: Component, buffer: Buffer): Component
---@field get_line_count fun(self: Component): number
---@field pop fun(self: Component): Line
---@field get fun(self: Component): Line[]
---@field get_text fun(self: Component): string[]
---@field get_colors fun(self: Component): table[]
---@field debug fun(self: Component, arg: { level: number, prefix: string|nil }): Component
local Component = {}

--- Create new component
---@return Component
function Component:new()
    local component = {}
    setmetatable(component, self)
    self.__index = self

    self.start_at = 0
    self.line_count = 0
    self.lines = {}
    self.text = {}
    self.colors = {}

    return component
end

--- Set start line number
---@param line_no number
---@return Component
function Component:from(line_no)
  self.start_at = line_no
  return self
end

--- Reset component
---@return Component
function Component:reset()

  self.lines = {}
  self.text = {}
  self.colors = {}
  self.line_count = 0

  return self
end

--- Add line to page
---@param lines Line[]
---@return Component
function Component:add(lines)

  for _, line in ipairs(lines) do

    table.insert(self.lines, line)

    local text = line.text or ''
    local meta = line.meta_text or ''
    local colors = line.colors or {}
    table.insert(self.text, text .. meta)

    for _, color in ipairs(colors) do
      table.insert(self.colors, color)
    end

    self.line_count = self.line_count + 1
  end

  return self
end

--- Add raw string to page
---@param string string|number
---@return Component
function Component:add_raw(string)

  local line = Line:new(self.line_count)
  line:add({ text = string })

  table.insert(self.lines, line)
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
---@param buffer TramBuffer
---@return Component
function Component:print(buffer)

  -- buffer:print(
  --   self.text,
  --   self.colors,
  --   self.start_at,
  -- )

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
function Component:get() return self.lines end

--- Get text
---@return string[]
function Component:get_text()
  return self.text
end

--- Get colors
---@return table[]
function Component:get_colors()
  return self.colors
end

--- Debug component and print to console
---@return Component
---@param arg { level: number, prefix: string|nil }
function Component:debug(arg)

  local level = arg.level or 1
  local type = self.type or 'unknown component type'
  local prefix = arg.prefix or nil

  if prefix then
    print(prefix)
  end
  print('Component [' .. type .. ']:')
  print('line_count: ' .. self.line_count)

  if level >= 2 then
    print('text:')
    for _, line in ipairs(self.text) do
      print('    ' .. line)
    end
    if level >= 3 then
      print('colors:')
      for _, color in ipairs(self.colors) do
        print('    ' .. vim.inspect(color))
      end
    end
  end
  print('-------------------')

  return self
end

return Component
