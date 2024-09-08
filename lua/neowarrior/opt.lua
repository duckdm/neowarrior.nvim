return {
  -- Whether to show the current filter at the top
  show_current_filter = true,
  -- Default filter
  filter = "",
  -- Default report
  report = "next",
  --@type normal|grouped|tree
  mode = "normal",
  --@type boolean Whether to expand all trees at start
  expanded = false,
  -- Default project name for tasks without project
  no_project_name = "No project defined",
  -- Task float
  float = {
    -- Enable floating window for tasks
    enabled = true,
    -- Max width of float in columns
    max_width = 60,
    -- Time (ms) before detail float is shown
    updatetime = 750
  },
  -- Set config values for specific directories.
  dir_setup = nil,
  -- Default reports available
  reports = {
    "active", "all", "blocked", "blocking", "completed", "list", "long",
    "ls", "minimal", "newest", "next", "oldest", "overdue", "projects",
    "ready", "recurring", "summary", "tags", "unblocked", "waiting",
  },
  -- Default filters available
  filters = {
    "due:", "due.not:", "\\(due.before:2d and due.not: \\)",
    "scheduled:", "scheduled.not:", "priority:H",
    "priority.not:H", "priority:M", "priority.not:M", "priority:L",
    "priority.not:L", "priority:", "priority.not:", "project:",
    "project.not:",
  },
  -- Default key mappings
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
  -- Default icons
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
