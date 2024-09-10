---@class Project
local Project = {}

function Project:new()
    local project = {}
    setmetatable(project, self)
    self.__index = self
    return project
end

return Project
