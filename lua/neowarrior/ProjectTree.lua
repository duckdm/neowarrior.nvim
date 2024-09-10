---@class ProjectTree
local ProjectTree = {}

function ProjectTree:new()
    local project_tree = {}
    setmetatable(project_tree, self)
    self.__index = self
    return project_tree
end

return ProjectTree
