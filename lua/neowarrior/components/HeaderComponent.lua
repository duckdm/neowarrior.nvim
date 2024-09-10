local Line = require('neowarrior.Line')
local Component = require('neowarrior.Component')

---@class HeaderComponent
---@field neowarrior NeoWarrior
local HeaderComponent = {}

--- Create a new HeaderComponent
---@param neowarrior NeoWarrior
---@param line_no number
---@return HeaderComponent
function HeaderComponent:new(neowarrior, line_no)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.line_no = line_no
    self.neowarrior = neowarrior

    -- local component = Component:new(self.line_no)
    -- component:add(self:get())

    return component
end

--- Get header line data
---@return Line[]
function HeaderComponent:get()

  local nw = self.neowarrior
  local keys = nw.config.keys
  local lines = {}

  local help = Line:new(self.line_no)
  help:add({ text = "(" .. keys.help.key .. ")help | " })
  help:add({ text = "(" .. keys.add.key .. ")add | " })
  help:add({ text = "(" .. keys.done.key .. ")done | " })
  help:add({ text = "(" .. keys.filter.key .. ")filter" })
  table.insert(lines, help)

  local report = Line:new(self.line_no + 1)
  report:add({ text = "(" .. keys.select_report.key .. ")report: " })
  report:add({
    text = "Report: " .. nw.current_report,
    color = "NeoWarriorTextInfo"
  })

  if nw.current_mode == 'grouped' then
    report:add({ text = " (Grouped by project)" })
  elseif nw.current_mode == 'tree' then
    report:add({ text = " (Tree view)" })
  end
  table.insert(lines, report)

  local filter = Line:new(self.line_no + 2)
  filter:add({ text = "(" .. keys.select_filter.key .. ")filter: " })
  filter:add({
    text = nw.current_filter,
    color = "NeoWarriorTextWarning"
  })
  table.insert(lines, filter)

  return lines
end

return HeaderComponent
