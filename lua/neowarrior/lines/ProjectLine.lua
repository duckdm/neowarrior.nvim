local colors = require "neowarrior.colors"

---@class ProjectLine
---@field line_no number
---@field project Project
---@field arg table
local ProjectLine = {}

--- Create a new ProjectLine
---@param tram Trambampolin
---@param project Project
---@return ProjectLine
function ProjectLine:new(tram, project)
    local project_component = {}
    setmetatable(project_component, self)
    self.__index = self

    self.tram = tram
    self.project = project

    return self
end

function ProjectLine:get_color()

  local conf = _Neowarrior.config.project_colors

  if conf then

    for match, value in pairs(conf) do

      local color = value

      if type(value) == "table" and value.match and value.color then
        match = value.match
        color = value.color
      end

      if string.match(self.project.name, match) then
        return _Neowarrior.config.colors[color].group
      end
    end
  end

  return _Neowarrior.config.colors.project.group
end

--- Get project line data
---@param arg table
---@return Line[]
function ProjectLine:into_line(arg)

  local conf = _Neowarrior.config
  local indent = arg.indent or ""
  local open = arg.open or false
  local icon = open and conf.icons.project_open or conf.icons.project
  local icon_alt = conf.icons.project_alt
  local name = self.project.name
  local disable_meta = arg.disable_meta or false
  local meta = arg.meta or { project = self.project.id }
  if disable_meta then meta = nil end
  local color = self:get_color()

  if arg.id_as_name then
    name = self.project.id
  end
  name = string.gsub(name, "%.", " " .. icon_alt .. " ")
  self.tram:col(indent, "")
  self.tram:col(icon .. " " .. name, color)

  local task_count = self.project.task_count
  if arg.enable_task_count == "eol" and task_count > 0 then
    self.tram:col(" " .. conf.icons.task .. " " .. task_count, "")
  end

  local total_estimate = self.project.estimate.total
  if arg.enable_total_estimate == "eol" and total_estimate > 0 then
    self.tram:col(
      " " .. conf.icons.est .. " " .. string.format("%.1f", total_estimate) .. "h",
      colors.get_estimate_color(total_estimate)
    )
  end

  if arg.enable_average_urgency == "eol" then
    self.tram:col(
      " " .. string.format("%.2f", self.project.urgency.average),
      colors.get_urgency_color(self.project.urgency.average)
    )
  end

  if arg.enable_total_urgency == "eol" then
    self.tram:col(
      " " .. string.format("%.2f", self.project.urgency.total),
      colors.get_urgency_color(self.project.urgency.total)
    )
  end

  self.tram:into_line({
    meta = meta,
  })

  local has_right_aligned_items = false
  if arg.enable_task_count == "right" and task_count > 0 then
    self.tram:col(" " .. conf.icons.task .. " " .. task_count, "NeoWarriorTextDefault")
    has_right_aligned_items = true
  end

  if arg.enable_total_estimate == "right" and total_estimate > 0 then
    self.tram:col(
      " " .. conf.icons.est .. " " .. string.format("%.1f", total_estimate) .. "h",
      colors.get_urgency_color(total_estimate)
    )
    has_right_aligned_items = true
  end

  if arg.enable_average_urgency == "right" then
    self.tram:col(
      " " .. string.format("%.2f", self.project.urgency.average),
      colors.get_urgency_color(self.project.urgency.average)
    )
    has_right_aligned_items = true
  end

  if arg.enable_total_urgency == "right" then
    self.tram:col(
      " " .. string.format("%.2f", self.project.urgency.total),
      colors.get_urgency_color(self.project.urgency.total)
    )
    has_right_aligned_items = true
  end

  if has_right_aligned_items then

    self.tram:into_virt_line({
      pos = "right_align"
    })

  end

  return self
end

return ProjectLine
