local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Buffer = require('neowarrior.Buffer')
local Window = require('neowarrior.Window')
local Float = require('neowarrior.Float')
local Page = require('neowarrior.Page')
local Taskwarrior = require('neowarrior.Taskwarrior')
local TaskPage = require('neowarrior.pages.TaskPage')
local colors   = require('neowarrior.colors')
local default_config = require('neowarrior.config')
local TaskCollection = require('neowarrior.TaskCollection')
local HeaderComponent = require('neowarrior.components.HeaderComponent')
local ListComponent = require('neowarrior.components.ListComponent')
local TaskLine = require('neowarrior.lines.TaskLine')
local Project = require('neowarrior.Project')
local ProjectCollection = require('neowarrior.ProjectCollection')
local ProjectLine = require('neowarrior.lines.ProjectLine')
local util = require('neowarrior.util')

---@class NeoWarrior
---@field public version string
---@field public config NeoWarrior.Config
---@field public user_config NeoWarrior.Config
---@field public buffer Buffer
---@field public window Window|nil
---@field public help_float Float|nil
---@field public task_float Float|nil
---@field public tw Taskwarrior
---@field public tasks TaskCollection
---@field public all_tasks TaskCollection
---@field public all_pending_tasks TaskCollection
---@field public projects ProjectCollection
---@field public project_names table
---@field public all_projects ProjectCollection
---@field public all_project_names table
---@field public project_tree table
---@field public toggled_trees table
---@field public current_filter string
---@field public current_report string
---@field public current_mode string
---@field public current_task Task
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
local NeoWarrior = {}

--- Constructor
---@return NeoWarrior
function NeoWarrior:new()
    local neowarrior = {}
    setmetatable(neowarrior, self)
    self.__index = self

    neowarrior.version = "v0.0.3"
    neowarrior.config = nil
    neowarrior.user_config = nil
    neowarrior.buffer = nil
    neowarrior.window = nil
    neowarrior.help_float = nil
    neowarrior.task_float = nil
    neowarrior.tw = Taskwarrior:new(neowarrior or self)
    neowarrior.tasks = TaskCollection:new()
    neowarrior.all_tasks = TaskCollection:new()
    neowarrior.all_pending_tasks = TaskCollection:new()
    neowarrior.projects = ProjectCollection:new()
    neowarrior.all_projects = ProjectCollection:new()
    neowarrior.project_names = {}
    neowarrior.all_project_names = {}
    neowarrior.project_tree = {}
    neowarrior.toggled_trees = {}
    neowarrior.current_filter = nil
    neowarrior.current_report = nil
    neowarrior.current_mode = nil
    neowarrior.current_task = nil

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
      if dir_setup.dir == cwd then
        self.config = vim.tbl_deep_extend('force', self.config, dir_setup)
      end
    end
  end

  --- For reset purposes
  self.config.default_filter = self.config.filter or ""
  self.config.default_report = self.config.report or "next"

  colors.set()

  if self.config.float.enabled then
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = vim.api.nvim_create_augroup('neowarrior-cursor-move', { clear = true }),
      callback = function()
        if self.task_float then
          self.task_float:close()
          self.task_float = nil
        end
      end,
    })
    vim.o.updatetime = self.config.float.delay
    vim.api.nvim_create_autocmd('CursorHold', {
      group = vim.api.nvim_create_augroup('neowarrior-cursor-hold', { clear = true }),
      callback = function()
        local line = vim.api.nvim_get_current_line()
        local description = self.buffer:get_meta_data('description')
        if description then
          local uuid = self.buffer:get_meta_data('uuid')
          local max_width = self.config.float.max_width
          local win_width = vim.api.nvim_win_get_width(0)
          local width = max_width
          local anchor = 'SW'
          local row = 0
          if self.buffer:get_cursor()[1] <= 10 then
            anchor = 'NW'
            row = 1
          end
          if win_width < max_width then
            width = win_width
          end

          if uuid then

            local task = self.tw:task(uuid)
            local project = self.all_projects:find(task.project)

            local float_buffer = Buffer:new({
              listed = false,
              scratch = true,
            })
            local page = Page:new(float_buffer)
            page:add_line(ProjectLine:new(self, 0, project, {
              disable_meta = true,
            }))
            page:add_line(TaskLine:new(self, 0, task, {
              disable_meta = true,
              disable_due = true,
              disable_estimate = true,
            }))
            page:add_raw(' ', '')
            page:add_raw('Urgency: ' .. task.urgency, colors.get_urgency_color(task.urgency))
            if task.priority then
              local priority_color = colors.get_priority_color(task.priority)
              page:add_raw('Priority: ' .. task.priority, priority_color)
            end
            if task.due then
              local due_relative = task.due:relative()
              local due_formatted = task.due:default_format()
              page:add_raw('Due: ' .. due_relative .. " (" .. due_formatted .. ")", colors.get_due_color(due_relative))
            end
            if task.estimate then
              page:add_raw('Estimate: ' .. task.estimate_string, colors.get_urgency_color(task.estimate))
            end
            self.task_float = Float:new(self, page, {
              relative = 'cursor',
              width = width,
              col = 0,
              row = row,
              enter = false,
              anchor = anchor,
            })
            self.task_float:open()

          end
        end
      end,
    })
  end

  return self
end

--- Init neowarrior
---@return NeoWarrior
function NeoWarrior:init()

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

  self.tasks = self.tw:tasks(self.current_report, self.current_filter)
  self.tasks:sort('urgency')
  self.project_names = util.extract('project', self.tasks:get())

  self.all_tasks = self.tw:tasks('all', 'description.not:')
  self.all_tasks:sort('urgency')
  self.all_project_names = util.extract('project', self.all_tasks:get())

  self.all_pending_tasks = TaskCollection:new()

  for _, task in ipairs(self.all_tasks:get()) do
    if task.status == 'pending' then
      self.all_pending_tasks:add(task)
    end
  end

  self.projects = self:generate_project_collection_from_tasks(self.tasks)
  self.projects:refresh()
  self.projects:sort('estimate.total')

  self.all_projects = self:generate_project_collection_from_tasks(self.all_tasks)
  self.all_projects:refresh()
  self.all_projects:sort('urgency.average')

  self.project_tree = self:fill_project_tree(
    self:generate_tree(self.project_names),
    Project:new({ name = 'root' }),
    self.projects
  )

  return self
end

--- Generate project collection from tasks
---@param tasks TaskCollection
---@return ProjectCollection
function NeoWarrior:generate_project_collection_from_tasks(tasks)

  local project_collection = ProjectCollection:new()

  for _, task in ipairs(tasks:get()) do

    local project_name = self.config.no_project_name
    local project_id = ""

    if task.project and task.project ~= "" then

      project_name = task.project
      project_id = task.project

    end

    if project_name then

      local project = project_collection:find(project_name)

      if not project then

        project = Project:new({
          id = project_id,
          name = project_name
        })

      end

      local task_in_project = project.tasks:find(task.uuid)

      if not task_in_project then
        project.tasks:add(task)
      end
      project_collection:add(project)

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

function NeoWarrior:show()

  local uuid = self.buffer:get_meta_data('uuid')
  local project = self.buffer:get_meta_data('project')
  local action = self.buffer:get_meta_data('action')

  if uuid then

    self:task(uuid)

  elseif project then

    self.current_filter = "project:" .. project
    self:list()

  elseif action then

    if action == 'help' then
      self:open_help()
    elseif action == 'report' then
      self:report_select()
    elseif action == 'filter' then
      self:filter_select()
    end

  end
end

--- Show add input
function NeoWarrior:add()
  self.buffer:save_cursor()
  local default_add_input = ""
  local prompt = "Task (ex: task name due:tomorrow etc): "
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
        self:task(self.current_task.uuid)
      else
        self.tw:add(input)
        self:refresh()
        self:list()
        self.buffer:restore_cursor()
      end
    end
  end)
end

--- Mark task as done
---@return self|nil
function NeoWarrior:mark_done()

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

      local choice = vim.fn.confirm("Are you sure you want to mark this task done?\n[" .. task.description .. "]\n", "Yes\nNo", 1, "question")

      if choice == 1 then
        self.tw:done(task)
      end
    end

    if self.current_task then
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

  vim.api.nvim_create_user_command("NeoWarriorOpen", function(opt)
    local valid_args = { 'current', 'above', 'below', 'left', 'right' }
    local split = opt and opt.fargs and opt.fargs[1] or 'below'
    if not vim.tbl_contains(valid_args, split) then
      split = 'below'
    end
    self:open({ split = split })
  end, { nargs = '*' })

  vim.api.nvim_create_user_command("NeoWarriorAdd", function()
    self:add()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorFilter", function()
    self:filter()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorFilterSelect", function()
    self:filter_select()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorReportSelect", function()
    self:report_select()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorRefresh", function()
    self:refresh()
    if self.current_task then
      self:task(self.current_task.uuid)
    else
      self:list()
    end
  end, {})

end

--- Set keymaps
--- TODO: keymap callbacks should call seperate functions in appropriate classes
function NeoWarrior:set_keymaps()

  if not self.config.keys then
    return
  end

  -- local opts = { noremap = true, silent = true }
  local default_keymap_opts = {
    buffer = self.buffer.id,
    noremap = true,
    silent = false
  }

  -- Add new task or annotation (annotation when on task page)
  vim.keymap.set("n", self.config.keys.add.key, function()
    self:add()
  end, default_keymap_opts)

  -- Show help float
  vim.keymap.set("n", self.config.keys.help.key, function()
    self:open_help()
  end, default_keymap_opts)

  -- Close help float
  vim.keymap.set("n", self.config.keys.close_help.key, function()
    self:close_help()
  end, default_keymap_opts)

  -- Mark task complete/done
  vim.keymap.set("n", self.config.keys.done.key, function()
    self:mark_done()
  end, default_keymap_opts)

  -- Start task
  vim.keymap.set("n", self.config.keys.start.key, function()
    self:start_stop()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.reset.key, function()
    self.current_filter = self.config.default_filter
    self.current_report = self.config.default_report
    self:refresh()
    self:list()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.toggle_tree_view.key, function()
    if self.current_mode == 'tree' then
      self.current_mode = 'normal'
    else
      self.current_mode = 'tree'
    end
    self:list()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.toggle_group_view.key, function()
    if self.current_mode == 'grouped' then
      self.current_mode = 'normal'
    else
      self.current_mode = 'grouped'
    end
    self:list()
  end, default_keymap_opts)

  -- Select task dependency
  vim.keymap.set("n", self.config.keys.select_dependency.key, function()
    self:refresh()
    local uuid = nil
    local task = nil
    if self.current_task then
      uuid = self.current_task.uuid
    else
      uuid = self.buffer:get_meta_data('uuid')
    end
    if not uuid then
      return
    end
    task = self.tw:task(uuid)
    local telescope_opts = require("telescope.themes").get_dropdown({})
    pickers.new(telescope_opts, {
      prompt_title = "Select dependency",
      finder = finders.new_table({
        results = self.all_pending_tasks:get(),
        entry_maker = function(entry)
          local task_line = TaskLine:new(self, 0, entry, {})
          return {
            value = entry,
            display = task_line.text,
            ordinal = task_line.text,
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
  end, default_keymap_opts)

  -- Toggle tree node
  vim.keymap.set("n", self.config.keys.toggle_tree.key, function()
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

  vim.keymap.set("n", self.config.keys.expand_all.key, function()
    self.buffer:save_cursor()
    for _, project in ipairs(self.all_projects:get()) do
      self.toggled_trees[project.id] = true
    end
    self:list()
    self.buffer:restore_cursor()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.collapse_all.key, function()
    self.buffer:save_cursor()
    self.toggled_trees = {}
    self:list()
    self.buffer:restore_cursor()
  end, default_keymap_opts)

  -- Show task
  vim.keymap.set("n", "<CR>", function()
    self:show()
  end, default_keymap_opts)
  vim.keymap.set("n", self.config.keys.enter.key, function()
    self:show()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.modify_select_project.key, function()
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
            local project_line = ProjectLine:new(self, 0, entry, {})
            return {
              value = entry.id,
              display = project_line.text,
              ordinal = project_line.text,
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

  vim.keymap.set("n", self.config.keys.modify_select_priority.key, function()
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
          end)
          return true
        end,
      })
      :find()
    end
  end, default_keymap_opts)

  --- Modify task due date
  vim.keymap.set("n", self.config.keys.modify_due.key, function()
    local uuid = nil
    if self.current_task then
      uuid = self.current_task.uuid
    else
      uuid = self.buffer:get_meta_data('uuid')
    end
    if uuid then
      local task = self.tw:task(uuid)
      self.buffer:save_cursor()
      local prompt = "Task due date: "
      vim.ui.input({
        prompt = prompt,
        cancelreturn = nil,
      }, function(input)
        if input then
          self.tw:modify(task, "due:" .. input)
          if self.current_task then
            self:task(self.current_task.uuid)
          else
            self:refresh()
            self:list()
          end
        end
      end)
      self.buffer:restore_cursor()
    end
  end, default_keymap_opts)

  --- Modify task
  vim.keymap.set("n", self.config.keys.modify.key, function()
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
        end
      end)
      self.buffer:restore_cursor()
    end
  end, default_keymap_opts)

  -- Back to list/refresh
  vim.keymap.set("n", '<Esc>', function() self:list() end, default_keymap_opts)
  vim.keymap.set("n", self.config.keys.back.key, function() self:list() end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.filter.key, '<Cmd>NeoWarriorFilter<CR>', default_keymap_opts)
  vim.keymap.set("n", self.config.keys.select_filter.key, '<Cmd>NeoWarriorFilterSelect<CR>', default_keymap_opts)

  vim.keymap.set("n", self.config.keys.select_report.key, '<Cmd>NeoWarriorReportSelect<CR>', default_keymap_opts)

  vim.keymap.set("n", self.config.keys.refresh.key, '<Cmd>NeoWarriorRefresh<CR>', default_keymap_opts)

end

--- Start/stop task
---@return NeoWarrior
function NeoWarrior:start_stop()

  self.buffer:save_cursor()
  local uuid = self.buffer:get_meta_data('uuid')

  if self.current_task then
    uuid = self.current_task.uuid
  end

  local task = nil

  if uuid then
    task = self.tw:task(uuid)
  end

  if task and task.start then

    self.tw:stop(task)

    if self.current_task then
      self:task(self.current_task.uuid)
    else
      self:list()
    end

    self.buffer:restore_cursor()

  elseif task then

    self.tw:start(task)
    self:task(task.uuid)

  end

  return self
end

--- Open help
---@return Float help_float
function NeoWarrior:open_help()

  local width = 40;
  local keys_array = {}

  -- Sort keymaps
  for _, value in pairs(self.config.keys) do
    table.insert(keys_array, { key = value.key, desc = value.desc })
  end
  table.sort(keys_array, function(a, b)
    return string.lower(a.key) < string.lower(b.key)
  end)

  local win_width = self.window:get_width()
  local page = Page:new(Buffer:new({
    listed = false,
    scratch = true,
  }))

  for _, key in ipairs(keys_array) do
    local key_string = string.format("%6s -> %s", key.key, key.desc)
    page:add_raw(key_string, '')
  end

  self.help_float = Float:new(self, page, {
    title = 'NeoWarrior help',
    width = width,
    col = math.floor((win_width - width) / 2),
    row = 5,
    enter = false,
  })
  self.help_float:open()

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

  project:refresh_recursive()
  self:sort_tree(project)

  return project
end

--- Sort tree
---@param project Project
---@return NeoWarrior
function NeoWarrior:sort_tree(project)

    project.projects:sort('urgency.average')
    project.tasks:sort('urgency')

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
  self:init()
  self:set_keymaps()
  self:create_user_commands()

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
    self.window = Window:new({
      buffer = self.buffer,
      win = win,
      enter = true,
    }, {
      split = split,
    })
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
  vim.cmd([[
  syntax match Metadata /{{{.*}}}/ conceal
  syntax match MetadataConceal /{{{[^}]*}}}/ contained conceal
]])

  self:refresh()
  self:after_initial_refresh()
  self:list()

  return self
end

--- List tasks
---@return NeoWarrior
function NeoWarrior:list()

  self.current_task = nil
  self.buffer:option('wrap', false, { win = self.window.id })

  if self.current_filter:find("project:" .. self.config.no_project_name) then
    self.current_filter = self.current_filter:gsub("project:" .. self.config.no_project_name, "project:")
  end

  Page:new(self.buffer)
    :add(HeaderComponent:new(self))
    :add(ListComponent:new(self, self.tasks))
    :print()

  self.buffer:restore_cursor()

  return self
end

--- Task page
---@param uuid string
function NeoWarrior:task(uuid)

  self.buffer:save_cursor()

  local task = self.tw:task(uuid)
  local task_page = TaskPage:new(self, task)
  task_page:print(self.buffer)
  self.current_task = task

end

function NeoWarrior:filter()
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
  local opts = require("telescope.themes").get_dropdown({})
  local filters = self.config.filters
  for _, project in ipairs(self.all_projects:get()) do
    table.insert(filters, "project:" .. project.name)
    table.insert(filters, "project.not:" .. project.name)
  end
  pickers
  .new(opts, {
    prompt_title = "Filter",
    finder = finders.new_table({
      results = filters,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local new_filter = prompt
        if selection and selection[1] then
          new_filter = selection[1]
        end
        self.current_filter = new_filter
        self:refresh()
        self:list()
      end)
      return true
    end,
  })
  :find()
end

function NeoWarrior:report_select()
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
      end)
      return true
    end,
  })
  :find()
end

return NeoWarrior
