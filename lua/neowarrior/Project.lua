local ProjectCollection = require('neowarrior.ProjectCollection')
local TaskCollection = require('neowarrior.TaskCollection')

---@class Project
---@field id string
---@field name string
---@field projects ProjectCollection
---@field tasks TaskCollection
---@field urgency table @{ total = 0, average = 0, max = 0, min = 0 }
---@field estimate table @{ total = 0, average = 0, max = 0, min = 0 }
---@field new fun(self: Project, data: table): Project
---@field refresh fun(self: Project): nil
local Project = {}

function Project:new(data)
    local project = {}
    setmetatable(project, self)
    self.__index = self

    project.id = data.id or data.name
    project.name = data.name
    project.projects = ProjectCollection:new()
    project.tasks = TaskCollection:new()
    project.task_count = 0
    project.urgency = { total = 0, average = 0, max = 0, min = 0 }
    project.estimate = { total = 0, average = 0, max = 0, min = 0 }

    return project
end

--- Sum data from child projects for tree
function Project:refresh_recursive()

    for _, project in ipairs(self.projects:get()) do

        project:refresh_recursive()

        local s_urg_avg = tonumber(self.urgency.average) or 0
        local p_urg_avg = tonumber(project.urgency.average) or 0

        self.task_count = self.task_count + project.task_count
        self.urgency.total = self.urgency.total + project.urgency.total
        self.urgency.average = s_urg_avg + p_urg_avg
        self.estimate.total = self.estimate.total + project.estimate.total
        self.estimate.average = self.estimate.average + project.estimate.average

    end

end

--- Refresh project data
function Project:refresh()

    self.urgency = { total = 0, average = 0, max = 0, min = 0 }
    self.estimate = { total = 0, average = 0, max = 0, min = 0 }
    self.task_count = 0

    for _, task in ipairs(self.tasks:get()) do

        if task.status and task.status == 'pending' then
            self.urgency.total = self.urgency.total + task.urgency
            if task.estimate and type(task.estimate) == 'number' then
                if task.estimate == nil then task.estimate = 0 end
                self.estimate.total = self.estimate.total + task.estimate
            end
            self.task_count = self.task_count + 1
        end

    end

    if self.urgency.total > 0 and self.task_count > 0 then
        self.urgency.average = self.urgency.total / self.task_count
    end

    if self.estimate.total > 0 and self.task_count > 0 then
        self.estimate.average = self.estimate.total / self.task_count
    end

    self.urgency.max = self.tasks:find_max('urgency')
    self.urgency.min = self.tasks:find_min('urgency')

    self.estimate.max = self.tasks:find_max('estimate')
    self.estimate.min = self.tasks:find_min('estimate')
end

return Project
