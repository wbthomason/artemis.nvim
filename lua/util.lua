-- Utility functions for Artemis

local util = {}

util.echo_special = function(msg, hl)
  -- Set the highlight
  vim.api.nvim_command('echohl ' .. hl)

  -- Echo the message
  vim.api.nvim_command('echomsg "[artemis] ' .. msg .. '"')

  -- Reset the highlight
  vim.api.nvim_command('echohl None')
end

util.echo_error   = function(msg) util.echo_special(msg, 'ErrorMsg') end
util.echo_warning = function(msg) util.echo_special(msg, 'WarningMsg') end

return util
