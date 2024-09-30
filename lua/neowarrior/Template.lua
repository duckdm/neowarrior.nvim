local Taskwarrior = require("neowarrior.Taskwarrior")
local TaskCollection = require("neowarrior.TaskCollection")

---@class Template
---@field tram Trambampolin
local Template = {}

function Template:new(tram)
  local template = {}
  setmetatable(template, self)

  template.tram = tram

  self.__index = self
  return template
end

function Template:cols(template)

  if type(template) == "string" then
    self.tram:line(self:replace_placeholders(template, {
      version = _Neowarrior.version
    }), {})
    return self
  end

  local tw = Taskwarrior:new()

  for _, template_col in ipairs(template) do

    local active = true
    local count = 0
    local color = template_col.color or ""
    local tasks = TaskCollection:new()
    local hl_group = ""

    if template_col.tasks then

      local filter_key = template_col.tasks[1] .. "_" .. template_col.tasks[2]
      if _Neowarrior.task_cache[filter_key] then
        tasks = _Neowarrior.task_cache[filter_key].tasks
      else
        tasks = tw:tasks(template_col.tasks[1], template_col.tasks[2])
        _Neowarrior.task_cache[filter_key] = {
          tasks = tasks,
          report = template_col.tasks[1],
          filter = template_col.tasks[2]
        }
      end
      count = tasks:count()

    else

      tasks = _Neowarrior.tasks
      count = tasks:count()

    end

    if type(color) == "function" then
      color = color(tasks)
    end

    if _Neowarrior.config.colors[color] then
      hl_group = _Neowarrior.config.colors[color].group
    end

    if type(template_col.active) == "function" then
      active = template_col.active(tasks)
    elseif type(template_col.active) == "boolean" then
      active = template_col.active
    end

    if active then
      self.tram:col(self:replace_placeholders(template_col.text, {
        count = count,
        tasks = tasks,
        version = _Neowarrior.version
      }), hl_group)
    end

  end

  return self
end
function Template:line(template)

  self:cols(template)
  self.tram:into_line({})

  return self
end

function Template:replace_placeholders(text, placeholders)

  if not text then
    return ""
  end

  for key, value in pairs(placeholders) do
    text = string.gsub(text, "{" .. key .. "}", value)
  end

  return text
end

return Template
