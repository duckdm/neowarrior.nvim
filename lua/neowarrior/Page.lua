--- FIX: this whole class should not be used
local Tram = require('trambampolin.init')
local Component = require('neowarrior.Component')
local Line = require('neowarrior.Line')
local util = require('neowarrior.util')

---@class Page
---@field components table
---@field line_count number
---@field component_count number
---@field buffer Buffer
---@field add fun(self: Page, component: Component):Page
---@field add_line fun(self: Page, line: Line): Page
---@field add_lines fun(self: Page, lines: Line[]): Page
---@field add_raw fun(self: Page, string: string, color: string):Page
---@field print fun(self: Page):Page
---@field get_line_count fun(self: Page):number
---@field nl fun(self: Page):Page
local Page = {}

--- Create a new Page
---@param buffer Buffer
---@return Page
function Page:new(buffer)
  local page = {}
  setmetatable(page, self)
  self.__index = self

  page.components = {}
  page.line_count = 0
  page.component_count = 0
  page.buffer = buffer
  page.tram = Tram:new()
  page.tram:set_buffer(buffer)

  return page
end

--- Add component to page
---@param component Component
---@return Page
function Page:add(component)

  table.insert(self.components, util.copy(component))
  self.line_count = self.line_count + component:get_line_count()
  self.component_count = self.component_count + 1

  return self
end

--- FIX: change to use trambampolin
--- Add line to page
---@param line Line
function Page:add_line(line)
  local line_component = Component:new()
  line_component:add({ line })
  self:add(line_component)

  return self
end

--- FIX: change to use trambampolin
--- Add line to page
---@param lines Line[]
function Page:add_lines(lines)

  for _, line in ipairs(lines) do
    self:add_line(line)
  end

  return self
end

--- FIX: change to use trambampolin
--- Add raw string to page
---@param string string
---@param color string
---@return Page
function Page:add_raw(string, color)

  local line = Line:new(0):add({ text = string, color = color })
  local raw = Component:new()
  raw.type = 'RawComponent: ' .. string
  raw:add({ line })
  self:add(raw)

  return self
end

--- Print page
---@return Page
function Page:print()

  self.buffer:unlock()
  local start_at = 0

  for _, component in ipairs(self.components) do
    component:from(start_at):print(self.buffer)
    start_at = start_at + component:get_line_count()
  end

  return self
end

--- Get line count
---@return number
function Page:get_line_count()
  return self.line_count
end

--- Add empty line to page
---@return Page
function Page:nl() self:add_raw('', '') return self end

return Page
