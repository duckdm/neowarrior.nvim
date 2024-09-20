local Line = require('neowarrior.Line')
local Component = require('neowarrior.Component')

---@class HeaderComponent
---@field neowarrior NeoWarrior
local HeaderComponent = {}

--- Create a new HeaderComponent
---@return Component
function HeaderComponent:new()
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    local component = Component:new()
    component.type = 'HeaderComponent'
    component:add(self:get())

    return component
end

--- Get header line data
---@return Line[]
function HeaderComponent:get()

  local nw = _Neowarrior
  local keys = nw.config.keys
  local lines = {}
  local line_no = 0

  if nw.config.header.text then
    local header = Line:new(line_no)
    local header_text = nw.config.header.text:gsub("{version}", nw.version)
    header:add({ text = header_text, color = "NeoWarriorTextHeader" })
    table.insert(lines, header)
    line_no = line_no + 1
  end

  if nw.config.header.enable_help_line then
    local help = Line:new(line_no)
    help:add({ text = "(" .. keys.help .. ")help | " })
    help:add({ text = "(" .. keys.add .. ")add | " })
    help:add({ text = "(" .. keys.done .. ")done | " })
    help:add({ text = "(" .. keys.filter .. ")filter" })
    help:add({ meta = { action = 'help' }})
    table.insert(lines, help)
    line_no = line_no + 1
  end

  if nw.config.header.enable_current_report then
    local report = Line:new(line_no)
    report:add({ text = "(" .. keys.select_report .. ")report: " })
    report:add({
      text = "Report: " .. nw.current_report,
      color = "NeoWarriorTextInfo"
    })
    report:add({ meta = { action = 'report' }})

    if nw.config.header.enable_current_view then
      if nw.current_mode == 'grouped' then
        report:add({ text = " (Grouped by project)" })
      elseif nw.current_mode == 'tree' then
        report:add({ text = " (Tree view)" })
      end
    end
    table.insert(lines, report)
    line_no = line_no + 1
  end

  if nw.config.header.enable_current_filter then
    local filter = Line:new(line_no)
    filter:add({ text = "(" .. keys.select_filter .. ")filter: " })
    filter:add({
      text = nw.current_filter,
      color = "NeoWarriorTextWarning"
    })
    filter:add({ meta = { action = 'filter' }})
    table.insert(lines, filter)
    line_no = line_no + 1
  end

  --- Add new line
  table.insert(lines, Line:new(line_no + 3):add({ text = "" }))

  return lines
end

return HeaderComponent
