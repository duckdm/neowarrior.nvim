local ProjectCollection = require('neowarrior.ProjectCollection')
local TaskCollection = require('neowarrior.TaskCollection')

---@class ProjectTree
local ProjectTree = {}

function ProjectTree:new()
    local project_tree = {}
    setmetatable(project_tree, self)
    self.__index = self

    project_tree.projects = ProjectCollection:new()
    project_tree.tasks = TaskCollection:new()
    project_tree.urgency = { total = 0, average = 0, max = 0, min = 0 }
    project_tree.estimate = { total = 0, average = 0, max = 0, min = 0 }

    return project_tree
end

return ProjectTree
