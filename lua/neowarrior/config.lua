---FIX: test all these
---@alias NeoWarrior.Config table
---@type NeoWarrior.Config
return {
  ---@type table Task line config
  task_line = {
    ---@type boolean Show warning icon colored based on urgency
    enable_warning_icon = true,
    ---@type boolean Show task-has-recurrance indicator
    enable_recur_icon = true,
    ---@type boolean Show priority (H, M, L)
    enable_priority = true,
    ---@type boolean Show due date
    enable_due_date = true,
    ---@type boolean Show estimate. NOTE: This is not a default field in taskwarrior
    enable_estimate = true,
  },
  ---@type boolean Whether to show the current filter at the top
  enable_current_filter = true,
  ---@type string Default taskwarrior filter
  filter = "",
  ---@type string Default taskwarrior report
  report = "next",
  ---@type "normal"|"grouped"|"tree"
  mode = "normal",
  ---@type boolean Whether to expand all trees at start
  expanded = false,
  ---@type string Default project name for tasks without project
  no_project_name = "No project defined",
  ---@type table Task float
  float = {
    ---@type boolean Enable floating window for tasks
    enabled = true,
    ---@type number Max width of float in columns
    max_width = 60,
    ---@type number Time in milliseconds before detail float is shown
    updatetime = 750
  },
  ---@type table|nil Set config values for specific directories. Most
  --- config values from this file should work per dir basis too.
  dir_setup = nil,
  ---@type table Default reports available (valid taskwarrior reports). Used
  ---in selects.
  reports = {
    "active", "all", "blocked", "blocking", "completed", "list", "long",
    "ls", "minimal", "newest", "next", "oldest", "overdue", "projects",
    "ready", "recurring", "summary", "tags", "unblocked", "waiting",
  },
  ---@type table Default filters available (valid taskwarrior filters). Used
  ---in selects.
  filters = {
    "due:", "due.not:", "\\(due.before:2d and due.not: \\)",
    "scheduled:", "scheduled.not:", "priority:H",
    "priority.not:H", "priority:M", "priority.not:M", "priority:L",
    "priority.not:L", "priority:", "priority.not:", "project:",
    "project.not:",
  },
  ---@type table Default key mappings
  keys = {
    help = { key = '?', desc = 'Help' },
    add = { key = 'a', desc = 'Add task' },
    done = { key = 'd', desc = 'Mark task done' },
    start = { key = 's', desc = 'Start task' },
    select_dependency = { key = 'D', desc = 'Select dependency' },
    filter = { key = 'F', desc = 'Filter tasks' },
    select_filter = { key = 'f', desc = 'Select filter' },
    toggle_group_view = { key = 'tg', desc = 'Toggle grouped view' },
    toggle_tree_view = { key = 'tt', desc = 'Toggle tree view' },
    select_report = { key = 'r', desc = 'Select report' },
    refresh = { key = 'R', desc = 'Refresh tasks' },
    reset = { key = 'X', desc = 'Reset filters' },
    collapse_all = { key = 'W', desc = 'Collapse all trees' },
    expand_all = { key = 'E', desc = 'Expand all trees' },
    toggle_tree = { key = '<Tab>', desc = 'Toggle tree' },
    enter = { key = 'l', desc = 'Show task details' },
    back = { key = 'h', desc = 'Back' },
    close_help = { key = 'q', desc = 'Close help' },
    modify = { key = 'MM', desc = 'Modify task' },
    modify_select_project = { key = 'Mp', desc = 'Modify project' },
    modify_select_priority = { key = 'MP', desc = 'Modify priority' },
    modify_due = { key = 'Md', desc = 'Modify due date' },
  },
  ---@type table Default icons
  icons = {
    task = "\u{f1db}",
    task_completed = "\u{f14a}",
    recur = "\u{f021}",
    project = "\u{f07b}",
    warning = "\u{f071}",
    annotated = "\u{f1781}",
    start = "\u{f040a}",
    due = "\u{f1442}",
    est = "\u{f0520}",
    deleted = "\u{f014}",
    depends = "\u{f111}",
  },
}
