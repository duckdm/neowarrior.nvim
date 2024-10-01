return {
  {
    cmd = "NeoWarriorOpen",
    callback = function(nw, opt)
      print("NeoWarriorOpen")
      local valid_args = { 'current', 'above', 'below', 'left', 'right', 'float' }
      local split = opt and opt.fargs and opt.fargs[1] or 'below'
      if not vim.tbl_contains(valid_args, split) then
        split = 'below'
      end
      nw:open({ split = split })
    end,
    opts = { nargs = '*' },
  },

  {
    cmd = "NeoWarriorAdd",
    callback = function(nw) nw:add() end,
  },

  {
    cmd = "NeoWarriorDone",
    callback = function(nw) nw:mark_done() end,
  },

  {
    cmd = "NeoWarriorStartStop",
    callback = function(nw) nw:start_stop() end,
  },

  {
    cmd = "NeoWarriorFilter",
    callback = function(nw)
      nw.buffer:save_cursor()
      nw:filter()
      nw.buffer:restore_cursor()
    end,
  },

  {
    cmd = "NeoWarriorFilterSelect",
    callback = function(nw)
      nw:filter_select()
    end,
  },

  {
    cmd = "NeoWarriorReportSelect",
    callback = function(nw)
      nw:report_select()
    end,
  },

  {
    cmd = "NeoWarriorRefresh",
    callback = function(nw)
      nw.buffer:save_cursor()
      nw:refresh()
      if nw.current_task then
        nw:task(nw.current_task.uuid)
      else
        nw:list()
      end
      nw.buffer:restore_cursor()
    end
  },
}
