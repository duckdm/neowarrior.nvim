---@alias NeoWarrior.Config table
---@type NeoWarrior.Config
return {
  ---@type boolean
  dev = false,

  ---@type table Task line config
  --- Note: Using more than one of these on the right currently causes some
  --- visual issues, the leftmost value's color will be used for the entire right
  --- "column".
  task_line = {
    ---@type false|"left"|"right" Show warning icon colored based on urgency
    enable_warning_icon = "left",
    ---@type false|"eol"|"right" Show urgency
    enable_urgency = "eol",
    ---@type false|"left" Show task-has-recurrance indicator
    enable_recur_icon = "left",
    ---@type false|"left" Show priority (H, M, L)
    enable_priority = "left",
    ---@type false|"left" Show due date
    enable_due_date = "left",
    ---@type false|"left" Show annotations icon
    enable_annotations_icon = "left",
    ---@type false|"left" Show tags in task line
    enable_tags = false,
    ---@type false|"left" Show estimate. Note: This is not a default
    ---field in taskwarrior
    enable_estimate = "left",
  },

  ---@type table Project line config.
  ---
  --- Note: These values are not always shown (on the task detail page for
  --- instance). Set values to either false, "eol" or "right" to enable
  --- or show them at specific positions.
  ---
  --- Note: Using more than one of these on the right currently causes some
  --- visual issues, the leftmost value's color will be used for the entire right
  --- "column".
  project_line = {
    ---@type false|"eol"|"right" Show task count
    enable_task_count = "eol",
    ---@type false|"eol"|"right" Show average urgency
    enable_average_urgency = "eol",
    ---@type false|"eol"|"right" Show total urgency
    enable_total_urgency = false,
    ---@type false|"eol"|"right" Show total estimate (Note: This is not a
    ---default field in taskwarrior)
    enable_total_estimate = "eol",
  },

  ---@type table Header config
  header = {
    ---@type string|nil Custom header text (disable with nil)
    text = "NeoWarrior {version}",
    ---@type boolean Whether to show help line
    enable_help_line = true,
    ---@type boolean Whether to show the current report at the top
    enable_current_report = true,
    ---@type boolean Whether to show the current view on the report line
    enable_current_view = true,
    ---@type boolean Whether to show the current filter at the top
    enable_current_filter = true,
  },

  ---@type string Default taskwarrior filter
  filter = "",

  ---@type string Default taskwarrior report
  report = "next",

  ---@type "normal"|"grouped"|"tree" Default view mode
  mode = "normal",

  ---@type boolean Whether to expand all trees at start
  expanded = false,

  ---@type string Default project name for tasks without project
  no_project_name = "no-project",

  ---@type table Task float
  float = {
    ---@type boolean|string Set to true to enable task float on hover. Alternatively
    ---you can set it to a key (string) to enable it on key press.
    enabled = true,
    ---@type number Time in milliseconds before detail float is shown. Only used if
    ---enabled is set to true.
    delay = 200,
    ---@type number Max width of float in columns
    max_width = 60,
  },

  ---@type number Timezone offset in hours
  time_offset = 0,

  ---@type table Colors and hl groups.
  ---You can use custom hl groups or just define colors for the existing
  ---highlight groups. A nil/false value for a color means it's
  ---disabled/transparent.
  colors = {
    neowarrior = { group = "NeoWarrior", fg = "#3eeafa", bg = "black" },
    default = { group = "", fg = nil, bg = nil },
    dim = { group = "NeoWarriorTextDim", fg = "#333333", bg = nil },
    danger = { group = "NeoWarriorTextDanger", fg = "#cc0000", bg = nil },
    warning = { group = "NeoWarriorTextWarning", fg = "#ccaa00", bg = nil },
    success = { group = "NeoWarriorTextSuccess", fg = "#00cc00", bg = nil },
    info = { group = "NeoWarriorTextInfo", fg = "#00aaff", bg = nil },
    danger_bg = { group = "NeoWarriorTextDangerBg", fg = "#ffffff", bg = "#cc0000" },
    info_bg = { group = "NeoWarriorTextInfoBg", fg = "#000000", bg = "#00aaff" },
    project = { group = "NeoWarriorGroup", fg = "#00aaff", bg = nil },
    annotation = { group = "NeoWarriorAnnotation", fg = "#00aaff", bg = nil },
    tag = { group = "NeoWarriorTag", fg = "#ffffff", bg = "#333333" },
  },
  --- Example using builtin highlight groups:
  -- colors = {
  --   default = { group = "" },
  --   dim = { group = "Whitespace" },
  --   danger = { group = "ErrorMsg" },
  --   warning = { group = "WarningMsg" },
  --   success = { group = "FloatTitle" },
  --   info = { group = "Question" },
  --   danger_bg = { group = "ErrorMsg" },
  --   project = { group = "Directory" },
  -- },

  ---@type table Breakpoints for coloring urgency, priorities etc.
  breakpoints = {

    ---@type table Urgency breakpoints. Uses equal or greater than for comparison.
    urgency = {
      { -100, "dim" }, --- Equal or higher than -100
      { 5, "warning" }, --- Equal or higher than 5
      { 10, "danger" }, --- Equal or higher than 10
    },

    ---@type table Estimate breakpoints (note that this is not a default
    ---taskwarrior field). Uses equal or greater than for comparison.
    estimate = {
      { 0, "danger" }, --- Equal or higher than 0
      { 1, "warning" }, --- Equal or higher than 1
      { 8, "default" }, --- Equal or higher than 8
    },

    ---@type table Due date breakpoints. Uses hours, and equal or lesser than
    ---for comparison. Use nil for a "catch all" value.
    due = {
      { 0.5, "danger_bg" }, --- Equal or lesser than 0.5 hours
      { 4, "danger" }, --- Equal or lesser than 4 hours
      { 48, "warning" }, --- Equal or lesser than 48 hours
      { nil, "dim" }, --- "Catch all" for the rest
    },

    ---@type table Priority colors.
    priority = {
      H = "danger",
      M = "warning",
      L = "success",
      None = "default",
    },
  },

  ---@type table|boolean Tag colors. Set to false to disable all. You can also use a table
  ---to specify a match pattern and color.
  tag_colors = {
    next = "danger_bg", --- matches tags called "next"
    blocked = "danger_bg", --- matches tags called "blocked"
    version = { match = "v.%..", color = "info_bg" }, -- match v*.*, v1.*, etc.
    version_full = { match = "v.%..%..", color = "info_bg" }, -- match v*.*.*, v1.*.*, etc.
    default = { match = ".*", color = "tag" }, -- match all other tags
  },

  ---@type nil|string Pad start of tags with this string. Use nil to disable.
  tag_padding_start = "+",
  ---@type nil|string Pad end of tags with this string. Use nil to disable.
  tag_padding_end = nil,

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

  ---@type table Default key mappings. Disable all by setting keys to nil or false.
  keys = {
    help = '?', --- Show help
    add = 'a', --- Add task
    done = 'd', --- Mark task as done
    start = 'S', --- Start task
    select_dependency = 'D', --- Select dependency
    filter = 'F', --- Input filter
    select_filter = 'f', --- Select filter
    toggle_group_view = 'tg', --- Toggle grouped view
    toggle_tree_view = 'tt', --- Toggle tree view
    select_report = 'r', --- Select report
    refresh = 'R', --- Refresh tasks
    reset = 'X', --- Reset filter
    collapse_all = 'W', --- Collapse all tree nodes
    expand_all = 'E', --- Expand all tree nodes
    toggle_tree = '<Tab>', --- Toggle tree node
    enter = 'l', --- Enter task/Activate line action
    back = 'h', --- Go back
    close_help = 'q', --- Close help
    modify = 'MM', --- Modify task
    modify_select_project = 'Mp', --- Modify project
    modify_select_priority = 'MP', --- Modify priority
    modify_due = 'Md', --- Modify due date
  },

  ---@type table Default icons
  icons = {
    task = "\u{f1db}",
    task_completed = "\u{f14a}",
    recur = "\u{f021}",
    project = "\u{f07b}",
    project_alt = "\u{f0256}",
    project_open = "\u{f115}",
    warning = "\u{f071}",
    annotated = "\u{f1781}",
    start = "\u{f040a}",
    due = "\u{f1442}",
    est = "\u{f0520}",
    deleted = "\u{f014}",
    depends = "\u{f111}",
  },
}
