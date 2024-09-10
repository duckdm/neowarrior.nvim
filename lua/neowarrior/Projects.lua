---@class Projects
---@field public projects table[Project]
local Projects = {}

function Projects:new()
    local project = {}
    setmetatable(project, self)
    self.__index = self
    return project
end

return Projects
