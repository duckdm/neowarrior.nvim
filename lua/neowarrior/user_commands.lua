return {
  {
    cmd = "Open",
    callback = function(nw, opt)
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
    cmd = "Help",
    callback = function(nw)
      nw:open_help()
    end,
  },

  {
    cmd = "Add",
    callback = function(nw) nw:add() end,
  },

  {
    cmd = "Done",
    callback = function(nw) nw:mark_done() end,
  },

  {
    cmd = "StartStop",
    callback = function(nw) nw:start_stop() end,
  },

  {
    cmd = "Filter",
    callback = function(nw)
      nw.buffer:save_cursor()
      nw:filter()
      nw.buffer:restore_cursor()
    end,
  },

  {
    cmd = "FilterSelect",
    callback = function(nw)
      nw:filter_select()
    end,
  },

  {
    cmd = "ReportSelect",
    callback = function(nw)
      nw:report_select()
    end,
  },

  {
    cmd = "Refresh",
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
