local util = require('neowarrior.util')

---@class ProjectCollection
---@field public projects table[Project]
---@field public new fun(self: ProjectCollection): ProjectCollection
---@field public add fun(self: ProjectCollection, project: Project): ProjectCollection
---@field public sort fun(self: ProjectCollection, key: string): ProjectCollection
---@field public get fun(self: ProjectCollection): Project[]
---@field public refresh fun(self: ProjectCollection): ProjectCollection
---@field public find fun(self: ProjectCollection, id: string): Project
---@field public count fun(self: ProjectCollection): number
local ProjectCollection = {}

--- Create new project collection
---@return ProjectCollection
function ProjectCollection:new()
    local project_collection = {}
    setmetatable(project_collection, self)
    self.__index = self

    project_collection.projects = {}

    return project_collection
end

--- Add project
---@param project Project
---@return ProjectCollection
function ProjectCollection:add(project)
    for _, p in ipairs(self.projects) do
        if p.name == project.name then
            return self
        end
    end
    table.insert(self.projects, project)
    return self
end

--- Sort project collection
---@param key string
---@return ProjectCollection
function ProjectCollection:sort(key)
  local projects_array = {}
  for _, proj in pairs(self.projects) do
    table.insert(projects_array, proj)
  end
  table.sort(projects_array, function(a, b)
    if key:find('%.') then
        local keys = util.split_string(key, '.')
        return a[keys[1]][keys[2]] > b[keys[1]][keys[2]]
    end
    return a[key] > b[key]
  end)
  self.projects = projects_array

  for _, project in ipairs(self.projects) do
    project.tasks:sort(_Neowarrior.current_sort, _Neowarrior.current_sort_direction)
  end

  return self
end

--- Get projects
---@return Project[]
function ProjectCollection:get()
    return self.projects
end

--- Refresh projects
---@return ProjectCollection
function ProjectCollection:refresh()

    for _, project in ipairs(self.projects) do
        project:refresh()
    end

    return self
end

--- Find project by name
---@param id string
---@return Project|nil
function ProjectCollection:find(id)
    for _, project in ipairs(self.projects) do
        if project.id == id then
            return project
        end
    end
    return nil
end

--- Get project count
---@return number
function ProjectCollection:count()
    return util.table_size(self.projects)
end

return ProjectCollection
