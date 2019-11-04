local default_sources  = require('default_sources')
local default_filters  = require('default_filters')
local default_matchers = require('default_matchers')
local window_fns       = require('window_fns')
local display_fns      = require('display_fns')

local util = require('util')
local types = require('types')

-- Set up structure
local artemis = {}

-- (source name, source function) table
artemis.sources  = vim.deepcopy(default_sources)

-- (filter name, filter function) table
artemis.filters  = vim.deepcopy(default_filters)

-- (matcher name, matcher function) table
artemis.matchers = vim.deepcopy(default_matchers)

-- Config properties table
artemis.config = {
  sources         = {},
  global_matchers = {},
  global_filters  = {},
  window_fn       = window_fns.floating_window,
  display_fns     = { default = display_fns.default_display_fn },
  spinner         = {'―', '╲', '❘', '╱'}
}

-- Re-export some types for convenience
local Source = types.Source
local Query = types.Query
local Collector = types.Collector

-- A search context
local Context = {}
function Context:new(buf, win, pipeline, start_dir, query)
  -- Set basic metadata fields
  local ctx = {
    buf = buf,
    win = win,
    pipeline = pipeline,
    search_dir = start_dir,
    query = query,
    active = false,
    results = Collector:new(),
    work_loop = vim.loop.new_work(self.run_source, self.finish_source)
  }

  -- Link the context, query graph, and results collector
  ctx.pipeline.query.link_collector(ctx.results)
  ctx.results.set_context(ctx)

  -- Setup methods
  setmetatable(ctx, self)

  return ctx
end

-- Start the source functions running
function Context:start()
  -- Do nothing if we're already running
  if self.active then
    return
  end

  -- Start each source function as new async work
  for _, source in ipairs(self.pipeline.query.sources) do
    vim.loop.queue_work(self.work_loop, source)
  end

  self.active = true
end

function Context:run_source(source)
  local results, err = source(self.query, self.search_dir)
  return source, results, err
end

function Context:finish_source(source, results, err)
  local source_data = self.results[source]
  source_data.running = false
  vim.tbl_extend('force', source_data.data, results)
  if err then
    util.echo_error('Error from source ' .. source .. ': ' .. error)
  end

  self.display()
end

function Context:update_filter(query)
end

function Context:display()
end

function Context:stop()
end

-- Start a new search
artemis.find = function(pipeline, start_dir, query)
  start_dir = start_dir or vim.api.nvim_eval('expand(%:p)')
  local buf, win = artemis.config.window_fn()
  local ctx = Context:new(buf, win, pipeline, start_dir, query)
  -- Set metadata
  artemis.__metadata.last.ctx = ctx
  -- TODO Start the spinner
  ctx:start()
  -- TODO Set up callbacks for the sources returning results
  local search_results = {}
  local running_counter = 0
end

-- Resume a previous search
artemis.resume = function()
  if artemis.__metadata.last.buf then
    artemis.config.window_fn(artemis.__metadata.last.buf)
  else
    util.echo_error('Nothing to resume!')
  end
end

-- Update the results display
-- TODO This would be better written only processing the new results rather than reprocessing
-- everything
artemis.update_display = function(buf, win, results)
  local lines = {}
  for source, source_results in pairs(results) do
    local format_fn = artemis.config.display_fns[source] or artemis.config.display_fns.default
    local source_lines = format_fn(source_results)
    lines[source] = table.concat(source_lines, '\n')
  end
  -- TODO Flatten everything, concat sections, write to buffer, update spinner
end

return artemis
