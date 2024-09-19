A simple taskwarrior plugin for NeoVim. Made this mostly for my self to have as a sidebar with my tasks inside neovim. 

![Screenshot](./screenshot.png)

# Requirements

- [Neovim v0.10.0](https://github.com/neovim/neovim/releases/tag/v0.10.0)
- [Taskwarrior](https://taskwarrior.org/)

## Optional

- A nerd font is highly recommended for the icons. Se config for setting custom icons.
- [folke/noice.nvim](https://github.com/folke/noice.nvim) for a nice cmdline UI.

# Features

- Add, start, modify and mark tasks done
- Filter tasks
  - Select from common filter
  - Custom filter input
- Select report
- Select dependency/parent task
- Show task details
- Task detail float (enabled on active line)
- Grouped and tree views (based on task project)
- Customizable keymaps
- Customizable reports and filters
- Customize config per directory


# Installation

## Simple setup with lazy.nvim

```lua
return {
  'duckdm/neowarrior.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    --- Optional but recommended for nicer inputs
    --- 'folke/noice.nvim',
  },
  --- See config example below
  opts = {}
}
```

## Example setup with dir specific configs

```lua
{
  'duckdm/neowarrior.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    --- Optional but recommended for nicer inputs
    --- 'folke/noice.nvim',
  },
  config = function()

    local nw = require('neowarrior')
    local home = vim.env.HOME
    nw.setup({
      report = "next",
      filter = "\\(due.before:2d or due: \\)",
      dir_setup = {
        {
          dir = home .. "/dev/nvim/neowarrior.nvim",
          filter = "project:neowarrior",
          mode = "tree",
          expanded = true,
        },
      }
    })
    vim.keymap.set("n", "<leader>nl", function() nw.open_left() end, { desc = "Open nwarrior on the left side" })
    vim.keymap.set("n", "<leader>nc", function() nw.open_current() end, { desc = "Open nwarrior below current buffer" })
    vim.keymap.set("n", "<leader>nb", function() nw.open_below() end, { desc = "Open nwarrior below current buffer" })
    vim.keymap.set("n", "<leader>na", function() nw.open_above() end, { desc = "Open nwarrior above current buffer" })
    vim.keymap.set("n", "<leader>nr", function() nw.open_right() end, { desc = "Open nwarrior on the right side" })
    vim.keymap.set("n", "<leader>nt", function() nw.focus() end, { desc = "Focus nwarrior" })
  end
}
```

# Available commands

| Command | Description |
| ------- | ----------- |
| `:NeoWarriorOpen` | Open NeoWarrior (default to below current buffer) |
| `:NeoWarriorOpen left` | Open NeoWarrior on the left side |
| `:NeoWarriorOpen right` | Open NeoWarrior on the right side |
| `:NeoWarriorOpen above` | Open NeoWarrior above current buffer |
| `:NeoWarriorOpen below` | Open NeoWarrior below current buffer |
| `:NeoWarriorOpen current` | Open NeoWarrior in current buffer |

# API methods
```lua
-- Open NeoWarrior (default to below current buffer)
require('neowarrior').open()

--- Open NeoWarrior on the left side
require('neowarrior').open_left()

--- Open NeoWarrior on the right side
require('neowarrior').open_right()

--- Open NeoWarrior above current buffer
require('neowarrior').open_above()

--- Open NeoWarrior below current buffer
require('neowarrior').open_below()

--- Open NeoWarrior in current buffer
require('neowarrior').open_current()

--- Focus NeoWarrior
require('neowarrior').focus()
```

# Default key maps

| Key | Description |
| --- | ----------- |
| ? | Help |
| a | Add task |
| d | Mark task done |
| s | Start task |
| D | Select dependency |
| F | Filter tasks |
| f | Select filter |
| tg | Toggle grouped view |
| tt | Toggle tree view |
| T | Reset tree view |
| r | Select report |
| R | Refresh tasks |
| X | Reset filters |
| W | Collapse all trees |
| E | Expand all trees |
| Tab | Toggle tree |
| l | Show task details |
| h | Back |
| q | Close help |
| MM | Modify task |
| Mp | Modify project |
| MP | Modify priority |
| Md | Modify due date |

# Default config values
```lua
{
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
    ---@type boolean Show urgency
    enable_urgency = true,
    ---@type boolean Show estimate. NOTE: This is not a default field in taskwarrior
    enable_estimate = true,
  },
  ---@type table Project line config. This is only used in tree view.
  project_line = {
    ---@type boolean Show task count
    enable_task_count = true,
    ---@type boolean Show average urgency
    enable_average_urgency = true,
    ---@type boolean Show total urgency
    enable_total_urgency = false,
    ---@type boolean Show total estimate
    enable_total_estimate = true,
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
  ---@type "normal"|"grouped"|"tree"
  mode = "normal",
  ---@type boolean Whether to expand all trees at start
  expanded = false,
  ---@type string Default project name for tasks without project
  no_project_name = "no-project",
  ---@type table Task float
  float = {
    ---@type boolean Enable floating window for tasks
    enabled = true,
    ---@type number Max width of float in columns
    max_width = 60,
    ---@type number Time in milliseconds before detail float is shown
    delay = 200,
  },
  ---@type number Timezone offset in hours
  time_offset = 0,
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
    start = 's', --- Start task
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
    tree_line = "│", --- NOTE: Not currently used
    tree_item = "├", --- NOTE: Not currently used
    tree_item_last = "└", --- NOTE: Not currently used
    task = "\u{f1db}",
    task_completed = "\u{f14a}",
    recur = "\u{f021}",
    project = "\u{f07b}",
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
```
