---@alias NeoWarrior.Config table
---@type NeoWarrior.Config
return {
  ---@type boolean
  dev = false,

  ui = {

    select = "native";

  },

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

  ---@type boolean|table Add custom colors to specific projects or disable with false.
  project_colors = {
    neowarrior = { match = "neowarrior.*", color = "neowarrior" },
  },

  ---@type table Header config
  header = {
    ---@type string|table|nil Custom header text (disable with nil)
    text = {
      { text = " NeoWarrior ", color = "neowarrior" },
      { text = " {version} ", color = "neowarrior_inverted" },
    },
    ---@type boolean Whether to show help line
    enable_help_line = true,
    ---@type boolean Whether to show the current report at the top
    enable_current_report = true,
    ---@type boolean Whether to show the current view on the report line
    enable_current_view = true,
    ---@type boolean Whether to show the current filter at the top
    enable_current_filter = true,
    ---@type boolean Whether to show the current sort option on the filter line
    enable_current_sort = false,
    ---@type boolean|table Show task info. Disable with false.
    task_info = {
      { text = "Tasks: " },
      { text = "{count}", color = "info" },
      {
        text = " Due soon: ",
        tasks = { "next", "due.before:2d and due.after:today" },
        active = function(tasks) return tasks:count() > 0 end
      },
      {
        text = " {count} ",
        tasks = { "next", "due.before:2d and due.after:today" },
        active = function(tasks) return tasks:count() > 0 end,
        color = function(tasks)
          if tasks:count() > 3 then
            return "danger_bg"
          end
          return "warning"
        end,
      },
    }
  },

  ---@type string Default taskwarrior filter
  filter = "",

  ---@type string Default taskwarrior report
  report = "next",

  ---@type "normal"|"grouped"|"tree" Default view mode
  mode = "normal",

  ---@type string Default sort option
  sort = "urgency",

  ---@type string Sort direction, ascending (asc) or descending (desc)
  sort_direction = "desc",

  ---@type boolean Whether to expand all trees at start
  expanded = false,

  ---@type string Default project name for tasks without project
  no_project_name = "no-project",

  ---@type table NeoWarrior float settings
  float = {
    ---@type number Width of float in columns, or if set to a number below 1,
    ---it will be calculated as a percentage of the window width.
    width = 60,
    ---@type number Height of float in rows, or if set to a number below 1,
    ---it will be calculated as a percentage of the window height.
    height = 0.8,
  },

  ---@type table Task float
  task_float = {
    ---@type boolean|string Set to true to enable task float on hover. Alternatively
    ---you can set it to a key (string) to enable it on key press.
    enabled = true,
    ---@type number Time in milliseconds before detail float is shown. Only used if
    ---enabled is set to true.
    delay = 200,
    ---@type number Max width of float in columns
    max_width = 60,
  },

  ---@type table Project float
  project_float = {
    ---@type boolean|string Set to true to enable project float on hover. Alternatively
    ---you can set it to a key (string) to enable it on key press.
    enabled = "e",
    ---@type number Time in milliseconds before detail float is shown
    delay = 200,
    ---@type number Max width of float in columns
    max_width = 40,
  },

  ---@type number Timezone offset in hours
  time_offset = 0,

  ---@type table Colors and hl groups.
  ---You can use custom hl groups or just define colors for the existing
  ---highlight groups. A nil/false value for a color means it's
  ---disabled/transparent.
  colors = {
    neowarrior = { group = "NeoWarrior", fg = "#3eeafa", bg = "black" },
    neowarrior_inverted = { group = "NeoWarriorInverted", fg = "black", bg = "#3cc8d7" },
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
    current_date = { group = "NeoWarriorCurrentDate", fg = "#000000", bg = "#00aaff" },
    marked_date = { group = "NeoWarriorMarkedDate", fg = "#ffffff", bg = "#00aa66" },
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

  ---@type table|nil Set config values for specific directories.
  --- Most config values from this file should work per dir
  --- basis too. Example:
  -- dir_setup = {
  --   {
  --     dir = HOME .. "/dev/neowarrior",
  --     mode = "tree",
  --     --- ... other config values
  --   },
  --   {
  --     match = "neowarrior", --- matches paths with "neowarrior" in the name
  --     mode = "tree",
  --     --- ... other config values
  --   }
  -- },
  dir_setup = nil,

  ---@type table Default reports available (valid taskwarrior reports). Used
  ---in selects.
  reports = {
    "active", "all", "blocked", "blocking", "completed", "list", "long",
    "ls", "minimal", "newest", "next", "oldest", "overdue", "projects",
    "ready", "recurring", "summary", "tags", "unblocked", "waiting",
  },

  ---@type string[]|table[] Default filters available (valid taskwarrior filters). Used
  ---in selects.
  filters = {
    { name = "Has due date", filter = "due.not:" },
    { name = "Has no due date", filter = "due:" },
    { name = "Due today", filter = "\\(due.before:2d and due.not: \\)" },
    { name = "Is not scheduled", filter = "scheduled:" },
    { name = "Is scheduled", filter = "scheduled.not:" },
    { name = "High priority", filter = "priority:H" },
    { name = "Medium priority", filter = "priority:M" },
    { name = "Low priority", filter = "priority:L" },
    { name = "No priority", filter = "priority:" },
    { name = "Has priority", filter = "priority.not:" },
    { name = "Has no project", filter = "project:" },
    { name = "Has project", filter = "project.not:" },
    {
      name = "Overdue",
      filter = "due.before:today and status:pending",
      sort = "due",
      sort_order = "asc",
    },
    {
      name = "Est. under 1 hour, this week",
      filter = "\\(est.before:1 and est.not: \\) and \\(due.before:7d or due: \\)",
      sort = "estimate",
      sort_order = "asc",
    },
  },

  ---@type table Task sort options for selects.
  task_sort_options = {
    { name = "Urgency (desc)", key = "urgency", direction = "desc" },
    { name = "Urgency (asc)", key = "urgency", direction = "asc" },
    { name = "Due (asc)", key = "due", direction = "asc" },
    { name = "Due (desc)", key = "due", direction = "desc" },
    { name = "Scheduled (asc)", key = "scheduled", direction = "asc" },
    { name = "Sceduled (desc)", key = "schedlued", direction = "desc" },
    { name = "Entry (from newest)", key = "entry", direction = "desc" },
    { name = "Entry (from oldest)", key = "entry", direction = "asc" },
    { name = "Modified (latest)", key = "modified", direction = "desc" },
    { name = "Modified (oldest)", key = "modified", direction = "asc" },
    { name = "Estimate (asc)", key = "estimate", direction = "asc" },
    { name = "Estimate (desc)", key = "estimate", direction = "desc" },
  },

  ---@type table Default key mappings. Disable all by setting keys to nil or false.
  keys = {
    help = '?', --- Show help
    add = 'a', --- Add task
    done = 'd', --- Mark task as done
    start = 'S', --- Start task
    select_dependency = 'Md', --- Select dependency
    search = 's', --- Search all tasks
    filter = 'F', --- Input filter
    select_filter = 'f', --- Select filter
    select_sort = 'o', --- Select sort
    toggle_group_view = 'tg', --- Toggle grouped view
    toggle_tree_view = 'tt', --- Toggle tree view
    toggle_agenda_view = 'ta', --- Toggle tree view
    select_report = 'r', --- Select report
    refresh = 'R', --- Refresh tasks
    reset = 'X', --- Reset filter
    collapse_all = 'W', --- Collapse all tree nodes
    expand_all = 'E', --- Expand all tree nodes
    toggle_tree = '<Tab>', --- Toggle tree node
    enter = 'l', --- Enter task/Activate line action
    back = 'h', --- Go back
    close = 'q', --- Close taskwarrior/close help
    modify = 'MM', --- Modify task
    modify_select_project = 'Mp', --- Modify project
    modify_select_priority = 'MP', --- Modify priority
    modify_due = 'MD', --- Modify due date
    next_tab = "L", --- Tab navigation, next tab
    prev_tab = "H", --- Tab navigation, previous tab
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
