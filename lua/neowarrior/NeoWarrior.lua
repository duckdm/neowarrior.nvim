local Func = require('neowarrior.func')
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

---@class NeoWarrior
---@field public config NeoWarrior.Config
---@field public user_config NeoWarrior.Config
---@field public buffer Buffer
---@field public window Window|nil
---@field public help_float Float|nil
---@field public tw Taskwarrior
---@field public tasks TaskCollection
---@field public all_tasks TaskCollection
---@field public all_pending_tasks TaskCollection
---@field public projects Projects
---@field public project_tree table
---@field public toggled_trees ProjectTree
---@field public current_filter string
---@field public current_report string
---@field public current_mode string
---@field public current_task Task
local NeoWarrior = {}

--- Constructor
---@return NeoWarrior
function NeoWarrior:new()
    local neowarrior = {}
    setmetatable(neowarrior, self)
    self.__index = self

    neowarrior.tw = Taskwarrior:new(self)

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
  colors.set()
  return self
end

--- Init neowarrior
---@return NeoWarrior
function NeoWarrior:init()

  self.current_mode = self.config.mode
  self.current_report = self.config.report
  self.current_filter = self.config.filter

  self:refresh()

  return self
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

--- Show add input
function NeoWarrior:add()
  self.buffer:save_cursor()
  local default_add_input = ""
  local prompt = "Task (ex: task name due:tomorrow etc): "
  local line = vim.api.nvim_get_current_line()
  local task_uuid = Func.get_meta_data(line, 'uuid')
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

  local task = Taskwarrior:task(uuid)
  local is_dependency = self.buffer:get_meta_data("dependency")
  local is_parent = self.buffer:get_meta_data("parent")

  if not is_parent then

    if is_dependency then

      -- TODO: remove dependency

    elseif uuid then

      local choice = vim.fn.confirm("Are you sure you want to mark this task done?\n[" .. task.description .. "]\n", "Yes\nNo", 1, "question")

      if choice == 1 then
        Taskwarrior:done(task)
      end
    end

    if self.current_task then
      self:task(self.current_task.uuid)
    else
      self:list()
    end
  end
  self.buffer:restore_cursor()

  return self
end

--- Create user commands
function NeoWarrior:create_user_commands()

  vim.api.nvim_create_user_command("NeoWarriorAdd", function()
    self:add()
  end, {})

end

--- Task page
---@param uuid string
function NeoWarrior:task(uuid)

  self.buffer:save_cursor()

  local task = Taskwarrior:task(uuid)
  local task_page = TaskPage:new(self, task)
  task_page:print(self.buffer)
  self.current_task = task

end

--- Set keymaps
--- FIX: keymap callbacks should call seperate functions in appropriate classes
function NeoWarrior:set_keymaps()

  -- local opts = { noremap = true, silent = true }
  local default_keymap_opts = {
    buffer = self.buffer.id,
    noremap = true,
    silent = false
  }

  vim.keymap.set("n", self.config.keys.add.key, function() self:add() end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.help.key, function()
    self:open_help()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.close_help.key, function()
    self:close_help()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.done.key, function()
    self:mark_done()
  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.start.key, function()

    self.buffer:save_cursor()
    local uuid = self.buffer:get_meta_data('uuid')

    if self.current_task then
      uuid = self.current_task.uuid
    end

    local task = nil

    if uuid then
      task = Taskwarrior:task(uuid)
    end

    if task and task.start then

      Taskwarrior:stop(task)

      if self.current_task then
        self:task(self.current_task.uuid)
      else
        self:list()
      end

      self.buffer:restore_cursor()

    elseif task then

      Taskwarrior:start(task)
      self:task(task.uuid)

    end

  end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.select_dependency.key, function()
  --   self:refresh()
  --   local line = vim.api.nvim_get_current_line()
  --   local uuid = Func.get_meta_data(line, 'uuid')
  --   local telescope_opts = require("telescope.themes").get_dropdown({})
  --   pickers.new(telescope_opts, {
  --     prompt_title = "Select dependency",
  --     finder = finders.new_table({
  --       results = self.all_tasks,
  --       entry_maker = function(entry)
  --         local task_icon = self.config.icons.task
  --         if entry.status and entry.status == "completed" then
  --           task_icon = self.config.icons.task_completed
  --         end
  --         if entry.status and entry.status == "deleted" then
  --           task_icon = self.config.icons.deleted
  --         end
  --         if Func.has_pending_dependencies(entry.depends, self.all_tasks) then
  --           task_icon = self.config.icons.depends
  --         end
  --         return {
  --           value = entry,
  --           display = task_icon .. ' ' .. entry.description,
  --           ordinal = entry.description,
  --         }
  --       end,
  --     }),
  --     sorter = conf.generic_sorter(opts),
  --     attach_mappings = function(prompt_bufnr)
  --       actions.select_default:replace(function()
  --         actions.close(prompt_bufnr)
  --         local selection = action_state.get_selected_entry()
  --         if uuid then
  --           Taskwarrior:add_dependency(uuid, selection.value.uuid)
  --           self:refresh()
  --           Page:tasks(Taskwarrior:tasks(self.current_report, self.current_filter), self.current_mode)
  --         end
  --       end)
  --       return true
  --     end,
  --   })
  --   :find()
  -- end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.toggle_tree.key, function()
  --   Buffer.save_cursor()
  --   Func.toggle_tree(self.toggled_trees)
  --   M.render_list()
  --   Buffer.restore_cursor()
  -- end, default_keymap_opts)

  vim.keymap.set("n", "<CR>", function()

    local uuid = Func.get_line_meta_data('uuid')
    local project = Func.get_line_meta_data('project')

    if uuid then

      -- FIX: Save cursor
      local task = Taskwarrior:task(uuid)
      local task_page = TaskPage:new(self, task)
      self.current_task = task
      task_page:print(self.buffer)

    elseif project then

      -- FIX: Render list
      --
    end

  end, default_keymap_opts)

  vim.keymap.set("n", self.config.keys.enter.key, function()

    local uuid = Func.get_line_meta_data('uuid')
    local project = Func.get_line_meta_data('project')

    if uuid then

      self:task(uuid)

    elseif project then

      -- FIX: Render list
      --
    end

  end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.modify_select_project.key, function()
  --   local line = vim.api.nvim_get_current_line()
  --   local uuid = Func.get_meta_data(line, 'uuid')
  --   if uuid then
  --     local telescope_opts = require("telescope.themes").get_dropdown({})
  --     pickers
  --     .new(telescope_opts, {
  --       prompt_title = "Set task project",
  --       finder = finders.new_table({
  --         results = NWProjects,
  --       }),
  --       sorter = conf.generic_sorter(opts),
  --       attach_mappings = function(prompt_bufnr)
  --         actions.select_default:replace(function()
  --           local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
  --           actions.close(prompt_bufnr)
  --           local selection = action_state.get_selected_entry()
  --           local mod_project = prompt
  --           if selection and selection[1] then
  --             mod_project = selection[1]
  --           end
  --           M.modify(uuid, "project:" .. mod_project)
  --           M.refresh()
  --         end)
  --         return true
  --       end,
  --     })
  --     :find()
  --   end
  -- end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.modify_select_priority.key, function()
  --   local line = vim.api.nvim_get_current_line()
  --   local uuid = Func.get_meta_data(line, 'uuid')
  --   if uuid then
  --     local telescope_opts = require("telescope.themes").get_dropdown({})
  --     pickers
  --     .new(telescope_opts, {
  --       prompt_title = "Set task priority",
  --       finder = finders.new_table({
  --         results = { "H", "M", "L", "None" },
  --       }),
  --       sorter = conf.generic_sorter(opts),
  --       attach_mappings = function(prompt_bufnr)
  --         actions.select_default:replace(function()
  --           local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
  --           actions.close(prompt_bufnr)
  --           local selection = action_state.get_selected_entry()
  --           local mod_priority = prompt
  --           if selection and selection[1] then
  --             mod_priority = selection[1]
  --           end
  --           if (mod_priority == "H") or (mod_priority == "M") or (mod_priority == "L") then
  --             M.modify(uuid, "priority:" .. mod_priority)
  --           else
  --             M.modify(uuid, "priority:")
  --           end
  --           M.export(NWCurrentFilter)
  --           M.render_list()
  --         end)
  --         return true
  --       end,
  --     })
  --     :find()
  --   end
  -- end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.modify_due.key, function()
  --   local line = vim.api.nvim_get_current_line()
  --   local uuid = Func.get_meta_data(line, 'uuid')
  --   Buffer.save_cursor()
  --   local prompt = "Task due date: "
  --   vim.ui.input({
  --     prompt = prompt,
  --     cancelreturn = nil,
  --   }, function(input)
  --     if input then
  --       M.modify(uuid, "due:" .. input)
  --       M.export(NWCurrentFilter)
  --       M.render_list()
  --     end
  --   end)
  --   Buffer.restore_cursor()
  -- end, default_keymap_opts)

  -- vim.keymap.set("n", self.config.keys.modify.key, function()
  --   local line = vim.api.nvim_get_current_line()
  --   local uuid = Func.get_meta_data(line, 'uuid')
  --   if not uuid and NWCurrentTask then
  --     uuid = NWCurrentTask
  --   end
  --   local task = nil
  --   if uuid then
  --     task = Data.task(uuid)
  --     Buffer.save_cursor()
  --     local prompt = 'Modify task ("description" due:21hours etc): '
  --     vim.ui.input({
  --       prompt = prompt,
  --       default = '"' .. task.description .. '"',
  --       cancelreturn = nil,
  --     }, function(input)
  --       if input then
  --         M.modify(uuid, input)
  --         if NWCurrentTask then
  --           M.show(NWCurrentTask)
  --         else
  --           M.export(NWCurrentFilter)
  --           M.render_list()
  --         end
  --       end
  --     end)
  --     Buffer.restore_cursor()
  --   end
  -- end, default_keymap_opts)

  vim.keymap.set("n", '<Esc>', function() self:list() end, default_keymap_opts)
  vim.keymap.set("n", self.config.keys.back.key, function() self:list() end, default_keymap_opts)
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

  local win_width = vim.api.nvim_win_get_width(0)
  local page = Page:new(self)

  for _, key in ipairs(keys_array) do
    local key_string = string.format("%6s | %s", key.key, key.desc)
    page:add(key_string, {})
  end

  self.help_float = Float:new(self, page, {
    title = 'NeoWarrior help',
    width = width,
    col = math.floor((win_width - width) / 2),
    row = 5,
  })
  self.help_float:open()

  return self.help_float
end

--- Close help
---@return NeoWarrior
function NeoWarrior:close_help()

  if self.help_float then
    self.help_float:close()
  end

  return self
end

function NeoWarrior:refresh()
  self.tasks = self.tw:tasks(self.current_report, self.current_filter)
  self.all_tasks = self.tw:tasks('all', 'description.not:')
  self.all_pending_tasks = TaskCollection:new()

  for _, task in ipairs(self.all_tasks:get()) do
    if task.status == 'pending' then
      self.all_pending_tasks:add(task)
    end
  end
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

  self:list()

  return self
end

--- List tasks
---@return NeoWarrior
function NeoWarrior:list()

  self:refresh()
  self.current_task = nil
  self.buffer:option('wrap', false, { win = self.window.id })

  local header_component = HeaderComponent:new(self, 0)
  header_component:print(self.buffer)

  -- local list = List:new(self, self.tasks)
  -- list:print(self.buffer)

  self.buffer:restore_cursor()

  return self
end

return NeoWarrior
