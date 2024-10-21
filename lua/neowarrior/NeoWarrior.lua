local Tram = require('trambampolin.init')
local Buffer = require('trambampolin.Buffer')
local Window = require('trambampolin.Window')

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Taskwarrior = require('neowarrior.Taskwarrior')
local TaskPage = require('neowarrior.pages.TaskPage')
local ProjectPage = require('neowarrior.pages.ProjectPage')
local colors   = require('neowarrior.colors')
local default_config = require('neowarrior.config')
local TaskCollection = require('neowarrior.TaskCollection')
local HeaderComponent = require('neowarrior.components.HeaderComponent')
local ListComponent = require('neowarrior.components.ListComponent')
local TagsComponent = require('neowarrior.components.TagsComponent')
local TaskLine = require('neowarrior.lines.TaskLine')
local Project = require('neowarrior.Project')
local ProjectCollection = require('neowarrior.ProjectCollection')
local ProjectLine = require('neowarrior.lines.ProjectLine')
local util = require('neowarrior.util')
local DateTimePicker = require('neowarrior.DateTimePicker')

---@class NeoWarrior
---@field public version string
---@field public config NeoWarrior.Config
---@field public user_config NeoWarrior.Config
---@field public buffer Buffer
---@field public window Window|nil
---@field public about_float Float|nil
---@field public help_float Float|nil
---@field public task_float Float|nil
---@field public task_floats Float[]
---@field public project_float Float|nil
---@field public project_floats Float[]
---@field public tw Taskwarrior
---@field public tasks TaskCollection
---@field public all_tasks TaskCollection
---@field public all_pending_tasks TaskCollection
---@field public projects ProjectCollection
---@field public grouped_projects ProjectCollection
---@field public project_names table
---@field public all_projects ProjectCollection
---@field public all_project_names table
---@field public project_tree table
---@field public toggled_trees table
---@field public current_filter string
---@field public current_sort string
---@field public current_sort_direction string
---@field public current_report string
---@field public current_mode string
---@field public key_descriptions table
---@field public current_task Task
---@field public current_project string|nil
---@field public keys table
---@field public task_cache table
---@field public current_page table|nil
---@field public back nil|table
---@field public dtp DateTimePicker
---@field public new fun(self: NeoWarrior): NeoWarrior
---@field public setup fun(self: NeoWarrior, config: NeoWarrior.Config): NeoWarrior
---@field public init fun(self: NeoWarrior): NeoWarrior
---@field public refresh fun(self: NeoWarrior): NeoWarrior
---@field public generate_project_collection_from_tasks fun(self: NeoWarrior, tasks: TaskCollection): ProjectCollection
---@field public get_config fun(self: NeoWarrior): NeoWarrior.Config
---@field public get_config_value fun(self: NeoWarrior, key: string): any
---@field public show fun(self: NeoWarrior)
---@field public add fun(self: NeoWarrior)
---@field public mark_done fun(self: NeoWarrior): NeoWarrior|nil
---@field public create_user_commands fun(self: NeoWarrior)
---@field public set_keymaps fun(self: NeoWarrior)
---@field public start_stop fun(self: NeoWarrior): NeoWarrior
---@field public open fun(self: NeoWarrior, opts: table): NeoWarrior
---@field public list fun(self: NeoWarrior): NeoWarrior
---@field public open_help fun(self: NeoWarrior): Float
---@field public close_help fun(self: NeoWarrior): NeoWarrior
---@field public insert_into_tree fun(self: NeoWarrior, tree: table, parts: table, index: number, parent_key: string)
---@field public fill_project_tree fun(self: NeoWarrior, tree: table, project: Project, project_pool: ProjectCollection): Project
---@field public sort_tree fun(self: NeoWarrior, project: Project): NeoWarrior
---@field public set_filter fun(self: NeoWarrior, filter: string): NeoWarrior
---@field public set_report fun(self: NeoWarrior, report: string): NeoWarrior
local NeoWarrior = {}

--- Constructor
---@return NeoWarrior
function NeoWarrior:new()
    local neowarrior = {}
    setmetatable(neowarrior, self)
    self.__index = self

    neowarrior.version = "v0.4.1"
    neowarrior.config = nil
    neowarrior.user_config = nil
    neowarrior.buffer = nil
    neowarrior.window = nil
    neowarrior.about_float = nil
    neowarrior.help_float = nil
    neowarrior.task_float = nil
    neowarrior.task_floats = {}
    neowarrior.project_float = nil
    neowarrior.project_floats = {}
    neowarrior.tw = Taskwarrior:new()
    neowarrior.tasks = TaskCollection:new()
    neowarrior.all_tasks = TaskCollection:new()
    neowarrior.all_pending_tasks = TaskCollection:new()
    neowarrior.projects = ProjectCollection:new()
    neowarrior.grouped_projects = ProjectCollection:new()
    neowarrior.all_projects = ProjectCollection:new()
    neowarrior.project_names = {}
    neowarrior.all_project_names = {}
    neowarrior.project_tree = {}
    neowarrior.toggled_trees = {}
    neowarrior.current_filter = nil
    neowarrior.current_sort = 'urgency'
    neowarrior.current_sort_direction = 'desc'
    neowarrior.current_report = nil
    neowarrior.current_mode = nil
    neowarrior.current_task = nil
    neowarrior.current_project = nil
    neowarrior.task_cache = {}
    neowarrior.current_page = nil
    neowarrior.back = nil
    neowarrior.dtp = nil
    neowarrior.keys = {
      {
        name = nil,
        keys = {
          { key = 'help', sort = 0, desc = 'Help' },
          { key = 'close', sort = 2, desc = 'Close NeoWarrior/Close help' },
        }
      },

      {
        name = "Task actions",
        keys = {
          { key = 'add', sort = 10, desc = 'Add task' },
          { key = 'enter', sort = 11, desc = 'Show task/Activate line action' },
          { key = 'back', sort = 12, desc = 'Back' },
          { key = 'done', sort = 13, desc = 'Mark task done' },
          { key = 'start', sort = 14, desc = 'Start task' },
          { key = 'modify', sort = 15, desc = 'Modify task' },
          { key = 'modify_select_project', sort = 16, desc = 'Modify project' },
          { key = 'modify_select_priority', sort = 17, desc = 'Modify priority' },
          { key = 'modify_due', sort = 18, desc = 'Modify due date' },
          { key = 'select_dependency', sort = 19, desc = 'Select dependency' },
        },
      },

      {
        name = 'Reports and filters',
        keys = {
          { key = 'search', sort = 28, desc = 'Search all tasks' },
          { key = 'select_sort', sort = 29, desc = 'Select task sorting' },
          { key = 'select_report', sort = 30, desc = 'Select report' },
          { key = 'select_filter', sort = 31, desc = 'Select filter' },
          { key = 'filter', sort = 32, desc = 'Filter input' },
          { key = 'reset', sort = 33, desc = 'Reset filter and report' },
        },
      },

      {
        name = 'Views',
        keys = {
          { key = 'toggle_group_view', sort = 33, desc = 'Toggle grouped view' },
          { key = 'toggle_tree_view', sort = 34, desc = 'Toggle tree view' },
          { key = 'toggle_agenda_view', sort = 35, desc = 'Toggle agenda view' },

          { key = 'collapse_all', sort = 36, desc = 'Collapse all trees' },
          { key = 'expand_all', sort = 37, desc = 'Expand all trees' },
          { key = 'toggle_tree', sort = 38, desc = 'Toggle tree' },

          { key = 'next_tab' , sort = 39, desc = 'Next tab' },
          { key = 'prev_tab' , sort = 40, desc = 'Previous tab' },
        }
      },

      {
        name = 'Other',
        keys = {
          { key = 'refresh', sort = 50, desc = 'Refresh data' },
        }
      }
    }

    return neowarrior
end

--- Setup
---@param config NeoWarrior.Config
---@return NeoWarrior
function NeoWarrior:setup(config)

  self.user_config = config
  self.config = vim.tbl_deep_extend(
    "force",
    default_config,
    self.user_config
  )
  if self.config.dir_setup and util.table_size(self.config.dir_setup) > 0 then

    local cwd = vim.uv.cwd()

    for _, dir_setup in ipairs(self.config.dir_setup) do

      local path = dir_setup.dir or nil
      local match = dir_setup.match or nil

      if cwd and match and cwd:find(match) then
        self.config = vim.tbl_deep_extend('force', self.config, dir_setup)
      elseif cwd and path and path == cwd then
        self.config = vim.tbl_deep_extend('force', self.config, dir_setup)
      end

    end

  end

  --- For reset purposes
  self.config.default_sort = self.config.sort or "urgency"
  self.config.default_sort_direction = self.config.sort_direction or "desc"
  self.config.default_filter = self.config.filter or ""
  self.config.default_report = self.config.report or "next"

  colors.set(self.config.colors)

  self:create_user_commands()

  return self
end

--- Close all floats
function NeoWarrior:close_floats()

  if self.task_float then
    self.task_float:close()
  end

  if self.project_float then
    self.project_float:close()
  end

  if self.help_float then
    self.help_float:close()
  end

  if util.table_size(self.task_floats) > 0 then
    for _, float in ipairs(self.task_floats) do
      if float then
        float:close()
      end
    end
    self.task_floats = {}
  end

  if util.table_size(self.project_floats) > 0 then
    for _, float in ipairs(self.project_floats) do
      if float then
        float:close()
      end
    end
    self.project_floats = {}
  end

end

--- Setup auto commands
function NeoWarrior:setup_autocmds()

  vim.api.nvim_create_autocmd('CursorMoved', {
    group = vim.api.nvim_create_augroup('neowarrior-cursor-move', { clear = true }),
    callback = function()

      self:close_floats()
      self.task_float = nil
      self.project_float = nil

    end,
  })

  if self.config.task_float.enabled == true then

    --- Delay before task float is shown
    vim.o.updatetime = self.config.task_float.delay
    vim.api.nvim_create_autocmd('CursorHold', {
      group = vim.api.nvim_create_augroup('neowarrior-cursor-hold', { clear = true }),
      callback = function()

          self:open_task_float()

      end,
    })

  end

  if self.config.project_float.enabled == true then

    --- Delay before task float is shown
    vim.o.updatetime = self.config.project_float.delay
    vim.api.nvim_create_autocmd('CursorHold', {
      group = vim.api.nvim_create_augroup('neowarrior-cursor-hold', { clear = true }),
      callback = function()

          self:open_project_float()

      end,
    })

  end

end

--- Show task float
function NeoWarrior:open_project_float()

  local project_id = self.buffer:get_meta_data('project')

  if project_id then

    local max_width = self.config.task_float.max_width
    local win_width = self.window:get_width()
    local width = max_width
    local anchor = 'SW'
    local cursor = self.buffer:get_cursor()
    local row = 0
    local col = 0 - cursor[2]
    if cursor[1] <= 10 then
      anchor = 'NW'
      row = 1
    end
    if win_width < max_width then
      width = win_width
    end

    local project = self.all_projects:find(project_id)

    local tram = Tram:new()
    ProjectLine:new(tram, project):into_line({
      disable_meta = true,
    })
    tram:into_line({})

    tram:nl()

    tram:col("Tasks: ", "")
    tram:col(project.task_count, _Neowarrior.config.colors.info.group)
    tram:into_line({})

    tram:nl()

    tram:col("Avg. urgency: ", "")
    tram:col(project.urgency.average, colors.get_urgency_color(project.urgency.average))
    tram:into_line({})

    tram:col("Total urgency: ", "")
    tram:col(project.urgency.total, colors.get_urgency_color(project.urgency.total))
    tram:into_line({})

    tram:col("Max urgency: ", "")
    tram:col(project.urgency.max, colors.get_urgency_color(project.urgency.max))
    tram:into_line({})

    tram:col("Min urgency: ", "")
    tram:col(project.urgency.min, colors.get_urgency_color(project.urgency.min))
    tram:into_line({})

    tram:nl()

    tram:col("Avg. estimate: ", "")
    tram:col(project.estimate.average, colors.get_urgency_color(project.estimate.average))
    tram:into_line({})

    tram:col("Total estimate: ", "")
    tram:col(project.estimate.total, colors.get_urgency_color(project.estimate.total))
    tram:into_line({})

    tram:col("Max estimate: ", "")
    tram:col(project.estimate.max, colors.get_urgency_color(project.estimate.max))
    tram:into_line({})

    tram:col("Min estimate: ", "")
    tram:col(project.estimate.min, colors.get_urgency_color(project.estimate.min))
    tram:into_line({})

    self.project_float = tram:open_float({
      relative = 'cursor',
      width = width,
      col = col,
      row = row,
      enter = false,
      anchor = anchor,
    })
    table.insert(self.project_floats, self.project_float)
  end
end

--- Show task float
function NeoWarrior:open_task_float()

  local description = self.buffer:get_meta_data('description')

  if description then

    local uuid = self.buffer:get_meta_data('uuid')
    local max_width = self.config.task_float.max_width
    local win_width = self.window:get_width()
    local width = max_width
    local anchor = 'SW'
    local cursor = self.buffer:get_cursor()
    local row = 0
    local col = 0 - cursor[2]
    if cursor[1] <= 10 then
      anchor = 'NW'
      row = 1
    end
    if win_width < max_width then
      width = win_width
    end

    if uuid then

      local task = self.tw:task(uuid)
      local project = self.all_projects:find(task.project)

      local tram = Tram:new()
      ProjectLine:new(tram, project):into_line({
        disable_meta = true,
      })
      tram:into_line({})

      TaskLine:new(tram, task):into_line({
        disable_meta = true,
        disable_due = true,
        disable_estimate = true,
        disable_has_blocking = true,
        disable_tags = true,
        line_conf = {
          enable_warning_icon = "left",
          enable_urgency = "eol",
        },
      })

      if task.tags then
        tram:nl()
        TagsComponent:new(tram, task.tags):line()
      end

      if task.depends and task.depends:count() > 0 then

        tram:nl()
        tram:line('Blocked by ' .. task.depends:count() .. ' task(s)', { color = _Neowarrior.config.colors.danger.group })

      end

      local task_parents = task:create_parent_collection()
      if task_parents then

        tram:nl()
        tram:line(
          'Blocking ' .. task_parents:count() .. ' task(s)',
          { color = _Neowarrior.config.colors.danger.group }
        )

      end

      tram:nl()

      tram:line('Urgency: ' .. task.urgency, { color = colors.get_urgency_color(task.urgency) })

      if task.priority then
        local priority_color = colors.get_priority_color(task.priority)
        tram:line('Priority: ' .. task.priority, { color = priority_color })
      end

      if task.due_dt then
        local due_relative = task.due_dt:relative()
        local due_hours = task.due_dt:relative_hours()
        local due_formatted = task.due_dt:default_format()
        tram:line('Due: ' .. due_relative .. " (" .. due_formatted .. ")", { color = colors.get_due_color(due_hours) })
      end

      if task.estimate then
        tram:line('Estimate: ' .. task.estimate_string, { color = colors.get_urgency_color(task.estimate) })
      end

      self.task_float = tram:open_float({
        relative = 'cursor',
        width = width,
        col = col,
        row = row,
        enter = false,
        anchor = anchor,
        zindex = 101,
      })
      table.insert(self.task_floats, self.task_float)

    end
  end

end

--- Init neowarrior
---@return NeoWarrior
function NeoWarrior:init()

  self.current_sort = self.config.sort
  self.current_sort_direction = self.config.sort_direction
  self.current_mode = self.config.mode
  self.current_report = self.config.report
  self.current_filter = self.config.filter

  return self
end

--- Second init, after first refresh, before list render
function NeoWarrior:after_initial_refresh()

  if self.config.expanded then
    for _, project in ipairs(self.all_projects:get()) do
      self.toggled_trees[project.id] = true
    end
  end

end

--- Refresh all data (tasks and projects)
---@return NeoWarrior
function NeoWarrior:refresh()

  self.task_cache = {}

  self.all_pending_tasks = self.tw:tasks('all', 'status:pending')
  self.all_pending_tasks:sort(self.current_sort, self.current_sort_direction)

  self.all_tasks = self.tw:tasks('all', 'description.not:')
  self.all_tasks:sort(self.current_sort, self.current_sort_direction)
  self.all_project_names = util.extract('project', self.all_tasks:get())

  self.tasks = self.tw:tasks(self.current_report, self.current_filter)
  self.tasks:sort(self.current_sort, self.current_sort_direction)

  self.project_names = util.extract('project', self.tasks:get())

  self.grouped_projects = self:generate_project_collection_from_tasks(self.tasks)
  self.grouped_projects:refresh()
  self.grouped_projects:sort('urgency.average')

  self.projects = self:generate_project_collection_from_tasks(self.tasks)
  self.projects:refresh()
  self.projects:sort('urgency.average')

  self.all_projects = self:generate_project_collection_from_tasks(self.all_tasks)
  self.all_projects:refresh()
  self.all_projects:sort('urgency.average')

  self.project_tree = self:fill_project_tree(
    self:generate_tree(self.project_names),
    Project:new({ name = 'root' }),
    util.copy(self.projects)
  )

  self.project_tree:refresh_recursive()
  self:sort_tree(self.project_tree)

  return self
end

--- Focus on neowarrior window
---@return boolean Returns false if no neowarrior window was found
function NeoWarrior:focus()

  local windows = vim.api.nvim_list_wins()
  for _, handle in ipairs(windows) do
    local buf_handle = vim.api.nvim_win_get_buf(handle)
    local buf_name = vim.api.nvim_buf_get_name(buf_handle)
    local buf_name_parts = util.split_string(buf_name, '/')
    buf_name = buf_name_parts[util.table_size(buf_name_parts)]
    if buf_name == "neowarrior" then
      vim.api.nvim_set_current_win(handle)
      return true
    end
  end

  return false
end

--- Generate project collection from tasks
---@param tasks TaskCollection
---@return ProjectCollection
function NeoWarrior:generate_project_collection_from_tasks(tasks)

  local project_collection = ProjectCollection:new()

  for _, task in ipairs(tasks:get()) do

    local project_name = self.config.no_project_name
    local project_names = {}

    if task.project and task.project ~= "" then

      project_name = task.project

    end

    local name_parts = {}
    local last_part = nil

    if string.find(project_name, "%.") then
      name_parts = vim.split(project_name, "%.")
    else
      name_parts = { project_name }
    end

    for _, part in ipairs(name_parts) do
      local part_name = last_part and last_part .. "." .. part or part
      table.insert(project_names, part_name)
      last_part = part_name
    end

    for _, project_name in ipairs(project_names) do

      if project_name then

        local project_id = project_name
        local project = project_collection:find(project_name)

        if not project then

          project = Project:new({
            id = project_id,
            name = project_name
          })

        end

        local task_in_project = project.tasks:find(task.uuid)

        if not task_in_project and task.project == project_id then
          project.tasks:add(task)
        end
        project_collection:add(project)

      end

    end

  end

  return project_collection
end

--- Get config
---@return NeoWarrior.Config
function NeoWarrior:get_config()
  return self.config
end

-- Get config value
---@param key string
---@return any
function NeoWarrior:get_config_value(key)
  return self.config[key]
end

--- Show task, list based on project or special actions (like when
--- cursor is on help line, report line or filter line in header).
---@return nil
function NeoWarrior:show()

  self:close_floats()
  self.buffer:save_cursor()

  local uuid = self.buffer:get_meta_data('uuid')
  local project = self.buffer:get_meta_data('project')
  local action = self.buffer:get_meta_data('action')
  self.back = self.buffer:get_meta_data('back')

  if uuid then

    self:task(uuid)

  elseif project then

    self:project(project, "pending")

  elseif action then

    if action == 'help' then
      self:open_help()
    elseif action == 'report' then
      self:report_select()
    elseif action == 'filter' then
      self:filter_select()
    elseif action == 'about' then
      self:open_about()
    end

  end
end

function NeoWarrior:open_about()

  local tram = Tram:new()
  tram:col(" NeoWarrior " .. _Neowarrior.version .. " ", _Neowarrior.config.colors.neowarrior.group)
  tram:col(" by ", "")
  tram:col(" duckdm ", _Neowarrior.config.colors.neowarrior_inverted.group)
  tram:into_line({})
  tram:nl()
  tram:line("Version: " .. self.version, { color = _Neowarrior.config.colors.info.group })
  tram:line("License: " .. "GNU GPLv3", { color = _Neowarrior.config.colors.info.group })
  tram:nl()
  tram:line("https://github.com/duckdm/neowarrior.nvim", {})

  self.about_float = self:open_float(tram:get_buffer(), {
    width = 50,
    height = 7,
    title = "About NeoWarrior",
    relative = "editor",
    enter = false,
    style = "minimal",
  })

  tram:print()

end

function NeoWarrior:get_editor_height() return vim.api.nvim_list_uis()[1].height end
function NeoWarrior:get_editor_width() return vim.api.nvim_list_uis()[1].width end

--- Open a float
---@param buffer Buffer
---@param opts table
---@return Window
function NeoWarrior:open_float(buffer, opts)

  local win_width = self:get_editor_width()
  local win_height = self:get_editor_height()
  local width = opts.width or 30
  local height = opts.height or 20

  if width <= 1 then
    width = math.floor(win_width * width)
  end

  if height <= 1 then
    height = math.floor(win_height * height)
  end

  if win_width < width then
    width = win_width
  end
  if win_height < height then
    height = win_height
  end

  local row = math.floor(win_height / 2) - (height / 2)
  local col = math.floor(win_width / 2) - (width / 2)
  local enter = true

  if opts.enter == false or opts.enter == true then
    enter = opts.enter
    opts.enter = nil
  end

  opts = {
    title = opts.title or nil,
    title_pos = opts.title_pos or "center",
    relative = opts.relative or "editor",
    width = width,
    height = height,
    row = opts.row or row,
    col = opts.col or col,
    anchor = opts.anchor or "NW",
    border = opts.border or "rounded",
    zindex = opts.zindex or 101,
    style = opts.style or nil,
  }

  return Window:new({
    buffer = buffer,
    enter = enter,
    win = -1,
  }, opts)

end

function NeoWarrior:add()

  self:close_floats()
  self.buffer:save_cursor()

  local default_add_input = ""
  local prompt = "Task (ex: task name due:tomorrow etc): "
  local project_id = self.buffer:get_meta_data('project')
  local task_uuid = self.buffer:get_meta_data('uuid')
  local task = nil

  if task_uuid then
    task = self.all_tasks:find_task_by_uuid(task_uuid)
    if (not task) or (not task.project) then
      task = nil
    end
  end

  if task then
    default_add_input = "project:" .. task.project .. " "
  elseif project_id then
    default_add_input = "project:" .. project_id .. " "
  elseif self.current_project then
    default_add_input = "project:" .. self.current_project .. " "
  elseif self.current_filter and string.find(self.current_filter, "project:") then
    for k, _ in string.gmatch(self.current_filter, "project:%w+[%.%w]*") do
      default_add_input = k
      break
    end
  end

  if self.current_task then
    default_add_input = ""
    prompt = "Annotate task"
  end

  vim.ui.input({
    prompt = prompt,
    default = default_add_input,
    cancelreturn = nil,
  }, function(input)
    if input then
      if self.current_task then
        self.tw:annotate(self.current_task, input)
        self:refresh()
        self:task(self.current_task.uuid)
      else
        self.tw:add(input)
        self:refresh()
        if self.current_project then
          local current_project_group = "pending"
          if self.current_page and self.current_page.group then
            current_project_group = self.current_page.group
          end
          self:project(self.current_project, current_project_group)
        else
          self:list()
        end
        self.buffer:restore_cursor()
      end
    end
  end)

end

--- Mark task as done
---@return self|nil
function NeoWarrior:mark_done()

  self:close_floats()
  self.buffer:save_cursor()
  local uuid = self.buffer:get_meta_data('uuid')
  if not uuid and self.current_task then
    uuid = self.current_task.uuid
  end
  if not uuid then
    return nil
  end

  local task = self.tw:task(uuid)
  local is_dependency = self.buffer:get_meta_data("dependency")
  local is_parent = self.buffer:get_meta_data("parent")

  if not is_parent then

    if is_dependency then

      -- TODO: remove dependency not implemented

    elseif uuid then

      local choice = nil

      if task.status == 'completed' then
        choice = vim.fn.confirm("Are you sure you want to mark this task un-done?\n[" .. task.description .. "]\n", "Yes\nNo", 1, "question")
      else
        choice = vim.fn.confirm("Are you sure you want to mark this task done?\n[" .. task.description .. "]\n", "Yes\nNo", 1, "question")
      end

      if choice == 1 then
        if task.status == 'completed' then
          self.tw:undone(task)
        else
          self.tw:done(task)
        end
      end
    end

    if self.current_task then
      self:refresh()
      self:task(self.current_task.uuid)
    else
      self:refresh()
      self:list()
    end
  end
  self.buffer:restore_cursor()

  return self
end

--- Create user commands
function NeoWarrior:create_user_commands()

  local cmds = require('neowarrior.user_commands')

  for _, cmd in ipairs(cmds) do
    vim.api.nvim_create_user_command("NeoWarrior" .. cmd.cmd, function(opt)
      cmd.callback(self, opt)
    end, cmd.opts or {})
  end

end

--- Set keymaps
--- TODO: keymap callbacks should call seperate functions in appropriate classes
function NeoWarrior:set_keymaps()

  if not self.config.keys then return end

  local default_keymap_opts = {
    buffer = self.buffer.id,
    noremap = true,
    silent = false
  }

  -- Add new task or annotation (annotation when on task page)
  if self.config.keys.add then
    vim.keymap.set("n", self.config.keys.add, function()
      self:add()
    end, default_keymap_opts)
  end

  -- Show help float
  if self.config.keys.help then
    vim.keymap.set("n", self.config.keys.help, function()
      self:open_help()
    end, default_keymap_opts)
  end

  -- Close help float
  if self.config.keys.close then
    vim.keymap.set("n", self.config.keys.close, function()
      if self.help_float then
        self:close_help()
      elseif self.about_float then
        self.about_float:close()
        self.about_float = nil
      else
        self:close()
      end
    end, default_keymap_opts)
  end

  -- Close help float
  if self.config.keys.close_help then
    vim.keymap.set("n", self.config.keys.close_help, function()
      self:close_help()
    end, default_keymap_opts)
  end

  -- Mark task complete/done
  if self.config.keys.done then
    vim.keymap.set("n", self.config.keys.done, function()
      self:mark_done()
    end, default_keymap_opts)
  end

  -- Start task
  if self.config.keys.start then
    vim.keymap.set("n", self.config.keys.start, function()
      self:start_stop()
    end, default_keymap_opts)
  end

  -- Reset filtera and report
  if self.config.keys.reset then
    vim.keymap.set("n", self.config.keys.reset, function()
      self.current_sort = self.config.default_sort
      self.current_sort_direction = self.config.default_sort_direction
      self.current_filter = self.config.default_filter
      self.current_report = self.config.default_report
      self:refresh()
      self:list()
    end, default_keymap_opts)
  end

  -- Toggle tree view
  vim.keymap.set("n", self.config.keys.toggle_tree_view, function()
    if self.current_mode == 'tree' then
      self.current_mode = 'normal'
    else
      self.current_mode = 'tree'
    end
    self:list()
  end, default_keymap_opts)

  -- Toggle agenda view
  vim.keymap.set("n", self.config.keys.toggle_agenda_view, function()
    if self.current_mode == 'agenda' then
      self.current_mode = 'normal'
    else
      self.current_mode = 'agenda'
    end
    self:list()
  end, default_keymap_opts)

  -- Toggle grouped view
  if self.config.keys.toggle_group_view then
    vim.keymap.set("n", self.config.keys.toggle_group_view, function()
      if self.current_mode == 'grouped' then
        self.current_mode = 'normal'
      else
        self.current_mode = 'grouped'
      end
      self:list()
    end, default_keymap_opts)
  end

  -- Select task dependency
  if self.config.keys.select_dependency then
    vim.keymap.set("n", self.config.keys.select_dependency, function()
      self:dependency_select()
    end, default_keymap_opts)
  end

  -- Toggle tree node
  if self.config.keys.toggle_tree then
    vim.keymap.set("n", self.config.keys.toggle_tree, function()
      self.buffer:save_cursor()
      local project_id = self.buffer:get_meta_data('project')
      if project_id then
        if self.toggled_trees[project_id] then
          self.toggled_trees[project_id] = false
        else
          self.toggled_trees[project_id] = true
        end
        self:list()
      end
      self.buffer:restore_cursor()
    end, default_keymap_opts)
  end

  -- Expand all trees
  if self.config.keys.expand_all then
    vim.keymap.set("n", self.config.keys.expand_all, function()
      self.buffer:save_cursor()
      for _, project in ipairs(self.all_projects:get()) do
        self.toggled_trees[project.id] = true
      end
      self:list()
      self.buffer:restore_cursor()
    end, default_keymap_opts)
  end

  --- Collapse all tree nodes
  if self.config.keys.collapse_all then
    vim.keymap.set("n", self.config.keys.collapse_all, function()
      self.buffer:save_cursor()
      self.toggled_trees = {}
      self:list()
      self.buffer:restore_cursor()
    end, default_keymap_opts)
  end

  -- Show task
  if self.config.keys.enter then
    vim.keymap.set("n", "<CR>", function()
      self:show()
    end, default_keymap_opts)
    vim.keymap.set("n", self.config.keys.enter, function()
      self:show()
    end, default_keymap_opts)
  end

  if self.config.keys.search then
    vim.keymap.set("n", self.config.keys.search, function()
      self:close_floats()
      self.buffer:save_cursor()
      local telescope_opts = require("telescope.themes").get_dropdown({})
      local icons = _Neowarrior.config.icons
      pickers.new(telescope_opts, {
        prompt_title = "Search tasks",
        finder = finders.new_table({
          results = self.all_tasks:get(),
          entry_maker = function(entry)

            local task_line = ""
            local status_ordinal = 0

            if entry.status ~= 'pending' then
              local status_icon = ""
              if entry.status == "completed" then
                status_icon = icons.task_completed .. " "
              end
              if entry.status == "deleted" then
                status_icon = icons.deleted .. " "
              end
              task_line = task_line .. "[" .. status_icon .. entry.status .. "] "
            end

            task_line = task_line .. entry.description

            if entry.status == 'completed' then status_ordinal = 100 end
            if entry.status == 'deleted' then status_ordinal = 1000 end

            task_line = task_line .. " (" .. icons.project .. " " .. entry.project .. ")"

            return {
              value = entry.uuid,
              display = task_line,
              ordinal = status_ordinal .. entry.description .. entry.project,
            }

          end,
        }),
        sorter = conf.generic_sorter(telescope_opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.value then
              self:task(selection.value)
            end
          end)
          return true
        end,
      })
      :find()
    end, default_keymap_opts)
  end

  -- Modify task project
  if self.config.keys.modify_select_project then
    vim.keymap.set("n", self.config.keys.modify_select_project, function()
      self:close_floats()
      self.buffer:save_cursor()
      local uuid = nil
      if self.current_task then
        uuid = self.current_task.uuid
      else
        uuid = self.buffer:get_meta_data('uuid')
      end
      if uuid then
        local task = self.tw:task(uuid)
        local telescope_opts = require("telescope.themes").get_dropdown({})
        pickers
        .new(telescope_opts, {
          prompt_title = "Set task project",
          finder = finders.new_table({
            results = self.all_projects:get(),
            entry_maker = function(entry)
              return {
                value = entry.id,
                display = entry.id,
                ordinal = entry.id,
              }
            end,
          }),
          sorter = conf.generic_sorter(telescope_opts),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local mod_project = prompt
              if selection and selection.value then
                mod_project = selection.value
              end
              self.tw:modify(task, "project:" .. mod_project)
              self:refresh()
              if self.current_task then
                self:task(self.current_task.uuid)
              else
                self:list()
              end
            end)
            return true
          end,
        })
        :find()
      end
    end, default_keymap_opts)
  end

  --- Modify task priority
  if self.config.keys.modify_select_priority then
    vim.keymap.set("n", self.config.keys.modify_select_priority, function()
      self:close_floats()
      self.buffer:save_cursor()
      local uuid = nil
      if self.current_task then
        uuid = self.current_task.uuid
      else
        uuid = self.buffer:get_meta_data('uuid')
      end
      if uuid then
        local task = self.tw:task(uuid)
        local telescope_opts = require("telescope.themes").get_dropdown({})
        pickers
        .new(telescope_opts, {
          prompt_title = "Set task priority",
          finder = finders.new_table({
            results = { "H", "M", "L", "None" },
          }),
          sorter = conf.generic_sorter(telescope_opts),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local mod_priority = prompt
              if selection and selection[1] then
                mod_priority = selection[1]
              end
              if (mod_priority == "H") or (mod_priority == "M") or (mod_priority == "L") then
                self.tw:modify(task, "priority:" .. mod_priority)
              else
                self.tw:modify(task, "priority:")
              end
              self:refresh()
              if self.current_task then
                self:task(self.current_task.uuid)
              else
                self:list()
              end
              self.buffer:restore_cursor()
            end)
            return true
          end,
        })
        :find()
      end
    end, default_keymap_opts)
  end

  --- Modify task due date
  if self.config.keys.modify_due then
    vim.keymap.set("n", self.config.keys.modify_due, function()
      self:modify_due()
    end, default_keymap_opts)
  end

  --- Modify task
  if self.config.keys.modify then
    vim.keymap.set("n", self.config.keys.modify, function()
      self:close_floats()
      self.buffer:save_cursor()
      local uuid = nil
      if self.current_task then
        uuid = self.current_task.uuid
      else
        uuid = self.buffer:get_meta_data('uuid')
      end
      if uuid then
        local task = self.tw:task(uuid)
        self.buffer:save_cursor()
        local prompt = 'Modify task ("description" due:21hours etc): '
        vim.ui.input({
          prompt = prompt,
          default = '"' .. task.description .. '"',
          cancelreturn = nil,
        }, function(input)
          if input then
            self.tw:modify(task, input)
            if self.current_task then
              self:task(self.current_task.uuid)
            else
              self:refresh()
              self:list()
            end
            self.buffer:restore_cursor()
          end
        end)
        self.buffer:restore_cursor()
      end
    end, default_keymap_opts)
  end

  local task_float_key = self.config.task_float.enabled or nil
  local project_float_key = self.config.project_float.enabled or nil

  --- Show task float
  if type(task_float_key) == "string" then
    vim.keymap.set("n", self.config.task_float.enabled, function()
      local uuid = self.buffer:get_meta_data('uuid')
      self:close_floats()
      if not self.task_float then
        self:open_task_float()
      else
        self.task_float = nil
      end
      if project_float_key == task_float_key and (not uuid) then
        if not self.project_float then
          self:open_project_float()
        else
          self.project_float = nil
        end
      end
    end, default_keymap_opts)
  end

  --- Show project float
  if task_float_key ~= project_float_key and type(project_float_key) == "string" then
    vim.keymap.set("n", self.config.project_float.enabled, function()
      local uuid = self.buffer:get_meta_data('uuid')
      self:close_floats()
      if not uuid then
        if not self.project_float then
          self:open_project_float()
        else
          self.project_float = nil
        end
      end
    end, default_keymap_opts)
  end

  -- Back to list/refresh
  if self.config.keys.back then
    vim.keymap.set("n", '<Esc>', function()
      self:list()
    end, default_keymap_opts)
    vim.keymap.set("n", self.config.keys.back, function()
      if self.back and self.back.type == "task" and self.back.uuid then
        self:task(self.back.uuid)
        self.back = nil
      elseif self.back and self.back.type == "project" and self.back.project then
        self:project(self.back.project, self.back.group or "pending")
        self.back = nil
      else
        self:list()
      end
    end, default_keymap_opts)
  end

  -- Filter tasks
  if self.config.keys.filter then
    vim.keymap.set("n", self.config.keys.filter, '<Cmd>NeoWarriorFilter<CR>', default_keymap_opts)
  end

  -- Select filter
  if self.config.keys.select_filter then
    vim.keymap.set("n", self.config.keys.select_filter, '<Cmd>NeoWarriorFilterSelect<CR>', default_keymap_opts)
  end

  -- Select report
  if self.config.keys.select_report then
    vim.keymap.set("n", self.config.keys.select_report, '<Cmd>NeoWarriorReportSelect<CR>', default_keymap_opts)
  end

  -- Refresh tasks
  if self.config.keys.refresh then
    vim.keymap.set("n", self.config.keys.refresh, '<Cmd>NeoWarriorRefresh<CR>', default_keymap_opts)
  end

  -- Select task sorting
  if self.config.keys.select_sort then
    vim.keymap.set("n", self.config.keys.select_sort, function()
      self:sort_select()
    end, default_keymap_opts)
  end

end

function NeoWarrior:sort_select()

  self.buffer:save_cursor()
  self:close_floats()

  local sort_options = self.config.task_sort_options or {}
  local telescope_opts = require("telescope.themes").get_dropdown({})

  pickers.new(telescope_opts, {
    prompt_title = "Select task sort order",
    finder = finders.new_table({
      results = sort_options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter(telescope_opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        self.current_sort = selection.value.key
        self.current_sort_direction = selection.value.direction or "desc"
        self:refresh()
        self:list()
        self.buffer:restore_cursor()
      end)
      return true
    end,
  })
  :find()
end

--- Start/stop task
---@return NeoWarrior
function NeoWarrior:start_stop()

  self:close_floats()
  self.buffer:save_cursor()
  local uuid = self.buffer:get_meta_data('uuid')

  if self.current_task then
    uuid = self.current_task.uuid
  end

  local task = nil

  if uuid then
    task = self.tw:task(uuid)
  end

  if task and task.start_dt then

    self.tw:stop(task)
    self:refresh()

    if self.current_task then
      self:task(self.current_task.uuid)
    else
      self:list()
    end

    self.buffer:restore_cursor()

  elseif task then

    self.tw:start(task)
    self:refresh()
    self:task(task.uuid)

  end

  return self
end

--- Open help
---@return Float help_float
function NeoWarrior:open_help()

  self:close_floats()

  local tram = Tram:new()
  local width = 0
  local pad = 0
  local key_length = 0
  local sep_length = 4
  local desc_length = 0

  for _, value in pairs(self.config.keys) do
    local len = string.len(value)
    if string.len(value) > pad then
      key_length = len
      pad = len
    end
  end

  pad = pad + 2

  tram:line(' ', {})

  for _, group in ipairs(self.keys) do

    if group.name then
      tram:line(string.format("%" .. pad + 4 .. "s", " ") .. group.name, _Neowarrior.config.colors.info.group)
    end

    for _, key in ipairs(group.keys) do

      local conf_key = self.config.keys[key.key]
      local desc = key.desc

      tram:col(string.format("%" .. pad .. "s", conf_key), _Neowarrior.config.colors.info.group)
      tram:col(" -> " .. desc, '')
      tram:into_line({})

      if string.len(key.desc) > desc_length then
        desc_length = string.len(key.desc)
      end
    end

    tram:line(' ', {})

  end

  width = key_length + sep_length + desc_length + 4
  local gwidth = vim.api.nvim_list_uis()[1].width
  local gheight = vim.api.nvim_list_uis()[1].height
  self.help_float = tram:open_float({
    title = 'NeoWarrior help',
    width = width,
    col = math.floor(gwidth / 2) - (width / 2),
    row = math.floor(gheight / 2) - (tram:get_line_no() / 2),
  })

  return self.help_float
end

--- Close help
---@return NeoWarrior
function NeoWarrior:close_help()

  if self.help_float then
    self.help_float:close()
    self.help_float = nil
  end

  return self
end

--- Insert into tree
---@param tree table
---@param parts table
---@param index number
---@param parent_key string
function NeoWarrior:insert_into_tree(tree, parts, index, parent_key)

  if index > #parts then
    return
  end
  local part = parts[index]
  local key = parent_key .. "." .. part
  if parent_key == "" then
    key = part
  end

  if not tree[key] then
    tree[key] = {}
  end

  self:insert_into_tree(tree[key], parts, index + 1, key)
end

--- Fill project tree
---@param tree table
---@param project Project
---@param project_pool ProjectCollection
---@return Project
function NeoWarrior:fill_project_tree(tree, project, project_pool)

  for id, ids in pairs(tree) do
    local p = project_pool:find(id)
    local id_parts = util.split_string(id, ".")
    if p then
      p.id = id
      p.name = id_parts[#id_parts]
    else
      p = Project:new({ id = id, name = id_parts[#id_parts] })
    end
    project.projects:add(p)
    self:fill_project_tree(ids, p, project_pool)
  end

  return project
end

--- Sort tree
---@param project Project
---@return NeoWarrior
function NeoWarrior:sort_tree(project)

    project.projects:sort('urgency.average')
    project.tasks:sort(self.current_sort, self.current_sort_direction)

    for _, p in ipairs(project.projects:get()) do
        self:sort_tree(p)
    end

    return self
end

--- Generate tree from table with project names
---@param projects table
---@return table
function NeoWarrior:generate_tree(projects)

  local tree = {}

  for _, category in ipairs(projects) do
    local parts = util.split_string(category, ".")
    self:insert_into_tree(tree, parts, 1, "")
  end

  return tree
end

--- Open
---@param opts table
---@return NeoWarrior
function NeoWarrior:open(opts)

  local split = opts.split or 'below'

  self.buffer = Buffer:new({})
  self:set_keymaps()
  self:setup_autocmds()

  if self:focus() then
    return self
  end

  if split == 'current' then

    vim.api.nvim_set_current_buf(self.buffer.id)
    self.window = Window:new({
      id = vim.api.nvim_get_current_win(),
      buffer = self.buffer,
      enter = true,
    }, {})

  else

    local win = -1
    if split == 'below' or split == 'above' then
      win = 0
    end

    opts = {
      split = split,
    }

    if split == "float" then

      local gwidth = vim.api.nvim_list_uis()[1].width
      local gheight = vim.api.nvim_list_uis()[1].height
      local width = self.config.float.width
      local height = self.config.float.height

      if width <= 1 then
        width = math.floor(gwidth * width)
      end

      if height <= 1 then
        height = math.floor(gheight * height)
      end

      if gwidth < width then
        width = gwidth
      end
      if gheight < height then
        height = gheight
      end
      local row = math.floor(gheight / 2) - (height / 2)
      local col = math.floor(gwidth / 2) - (width / 2)

      opts = {
        relative = "win",
        width = width,
        height = height,
        row = row,
        col = col,
        anchor = "NW",
        border = "rounded",
      }

    end

    self.window = Window:new({
      buffer = self.buffer,
      win = win,
      enter = true,
    }, opts)

  end

  self.buffer:set_name('neowarrior')
  self.buffer:lock()
  self.buffer:option('buftype', 'nofile', { buf = self.buffer.id })
  self.buffer:option('bufhidden', 'wipe', { buf = self.buffer.id })
  self.buffer:option('swapfile', false, { buf = self.buffer.id })
  self.buffer:option('conceallevel', 2, { win = self.window.id })
  self.buffer:option('concealcursor', 'nc', { win = self.window.id })
  self.buffer:option('wrap', false, { win = self.window.id })
  self.buffer:option('filetype', 'neowarrior', { buf = self.buffer.id })

--   vim.cmd([[
--   syntax match Metadata /{{{.*}}}/ conceal
--   syntax match MetadataConceal /{{{[^}]*}}}/ contained conceal
-- ]])

  self:refresh()
  self:after_initial_refresh()
  self:list()

  return self
end

function NeoWarrior:modify_due()

  self:close_floats()
  self.buffer:save_cursor()

  local uuid = nil
  local task = nil

  if self.current_task then
    uuid = self.current_task.uuid
    task = self.current_task
  else
    uuid = self.buffer:get_meta_data('uuid')
    if uuid then
      task = self.tw:task(uuid)
    end
  end

  self.dtp = DateTimePicker:new({

    row = 0,
    col = 2,
    title = "Select due date",
    select_time = true,
    mark = {
      { date = task and task.due_dt or nil, }
    },
    on_select = function(date, dtp)

      dtp:close()

      if date and task then
        self.buffer:save_cursor()
        self.tw:modify(task, "due:" .. date:format("%Y%m%dT%H%M%SZ"))
        if self.current_task then
          self:task(self.current_task.uuid)
        else
          self:refresh()
          self:list()
        end
      end

      self.buffer:restore_cursor()

    end,

  })

  self.dtp:open();

end

--- Close neowarrior
function NeoWarrior:close()

  self:close_floats()
  self.window:close()

end

--- List tasks
---@return NeoWarrior
function NeoWarrior:list()

  self:close_floats()
  self.current_task = nil
  self.buffer:option('wrap', false, { win = self.window.id })

  if self.current_filter:find("project:" .. self.config.no_project_name) then
    self.current_filter = self.current_filter:gsub("project:" .. self.config.no_project_name, "project:")
  end

  local tram = Tram:new():set_buffer(self.buffer)
  HeaderComponent:new(tram):set()
  ListComponent:new(tram, self.tasks):set()

  tram:print()

  self.buffer:restore_cursor()
  self.current_page = { tram = tram, name = 'list' }

  return self
end

--- Task page
---@param uuid string
function NeoWarrior:task(uuid)

  self.buffer:save_cursor()

  local task = self.tw:task(uuid)
  local task_page = TaskPage:new(self.buffer, task)
  task_page:print(self.buffer)
  self.current_task = task
  self.current_page = { tram = task_page.tram, name = 'task' }

end

--- Project page
---@param project string Project "id"
function NeoWarrior:project(project, group)

  local project_page = ProjectPage:new(self.buffer, project)
  project_page:print(group)
  self.current_project = project
  self.current_page = {
    tram = project_page.tram,
    name = 'project',
    group = group,
  }
  self.buffer:restore_cursor()

end

function NeoWarrior:filter()
  self:close_floats()
  local default_filter_input = self.current_filter or ""
  vim.ui.input({
    prompt = "Filter (ex: next project:neowarrior",
    default = default_filter_input,
    cancelreturn = nil,
  }, function(input)
    if input then
      self.current_filter = input
      self:refresh()
      self:list()
    end
  end)
end

--- Open telescope filter selection
function NeoWarrior:filter_select()

  self.buffer:save_cursor()
  self:close_floats()

  local opts = require("telescope.themes").get_dropdown({})
  local filters = self.config.filters
  local icons = _Neowarrior.config.icons

  for _, project in ipairs(self.all_projects:get()) do
    table.insert(filters, {
      name = icons.project .. " In " .. project.name,
      filter = "project:" .. project.name
    })
    table.insert(filters, {
      name = icons.project .. " Not in " .. project.name,
      filter = "project.not:" .. project.name
    })
  end

  pickers.new(opts, {
    prompt_title = "Filter",
    finder = finders.new_table({
      results = filters,
      entry_maker = function(entry)

        if type(entry) ~= "table" then
          entry = {
            name = entry,
            filter = entry,
          }
        end

        return {
          value = entry,
          display = entry.name .. " (" .. entry.filter .. ")",
          ordinal = entry.name .. " " .. entry.filter,
        }

      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local new_filter = prompt
        local current_sort = self.current_sort
        local current_sort_direction = self.current_sort_direction
        if selection and selection.value then

          new_filter = selection.value.filter

          if selection.value.sort then
            self.current_sort = selection.value.sort
          else
            self.current_sort = current_sort
          end

          if selection.value.sort_order then
            self.current_sort_direction = selection.value.sort_order
          else
            self.current_sort_direction = current_sort_direction
          end

        end
        self.current_filter = new_filter
        self:refresh()
        self:list()
        self.buffer:restore_cursor()
      end)
      return true
    end,
  })
  :find()
end

function NeoWarrior:report_select()
  self.buffer:save_cursor()
  self:close_floats()
  local opts = require("telescope.themes").get_dropdown({})
  pickers
  .new(opts, {
    prompt_title = "Select report",
    finder = finders.new_table({
      results = self.config.reports,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        self.current_report = selection[1]
        self:refresh()
        self:list()
        self.buffer:restore_cursor()
      end)
      return true
    end,
  })
  :find()
end

--- Set filter, refresh and show list
---@param filter string
---@return NeoWarrior
function NeoWarrior:set_filter(filter)
  self.current_filter = filter
  self:refresh()
  self:list()

  return self
end

--- Set report, refresh and show list
---@param report string
---@return NeoWarrior
function NeoWarrior:set_report(report)
  self.current_report = report
  self:refresh()
  self:list()

  return self
end

--- Show depepndency select dropdown
---@return NeoWarrior
function NeoWarrior:dependency_select()

  self.buffer:save_cursor()
  self:close_floats()
  self:refresh()

  local uuid = nil
  local task = nil

  if self.current_task then
    uuid = self.current_task.uuid
  else
    uuid = self.buffer:get_meta_data('uuid')
  end
  if not uuid then
    return self
  end

  task = self.tw:task(uuid)
  local telescope_opts = require("telescope.themes").get_dropdown({})
  pickers.new(telescope_opts, {
    prompt_title = "Select dependency",
    finder = finders.new_table({
      results = self.all_pending_tasks:get(),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.description .. " - " .. entry.urgency,
          ordinal = entry.description,
        }
      end,
    }),
    sorter = conf.generic_sorter(telescope_opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if task then
          self.tw:add_dependency(task, selection.value.uuid)
          self:refresh()
          self:list()
        end
      end)
      return true
    end,
  })
  :find()

  return self
end

return NeoWarrior
