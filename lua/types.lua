-- Common types
local types = {}

-- TODO: Maybe add typechecking to graph connections to ensure proper linkage and data flow?
-- Graph node
local Node = { name = nil, output = nil }
function Node:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Node:connect(node)
  self.output = node
end

function Node:set_name(name)
  self.name = name
end

-- Data sources
local Source = Node:new()
-- A source may be synchronous or asynchronous, but is responsible for calling its output with every
-- datum it produces. It takes arguments for the search directory and initial query
function Source:start(_, _)
  error('start() unimplemented for source ' .. self.name, 2)
end

-- Data filters
local Filter = Node:new()
-- A filter is called with a datum and returns either nil or a datum. It is responsible for calling
-- its output with its result
function Filter:__call(_)
  error('__call(1) unimplemented for filter ' .. self.name, 2)
end

-- Query graphs
local Query = {}
function Query:new(sink, ...)
  local graph = {
    sources = {...},
    sink = sink
  }

  setmetatable(graph, self)
  return graph
end

-- Link the final filter node to a collector for the results
function Query:link_collector(collector)
  self.sink.output = collector
end

-- Result collector
local Collector = {}
function Collector:new()
  local collector = {
    data = {},
    context = nil
  }

  setmetatable(collector, self)
  return collector
end

function Collector:set_context(context)
  self.context = context
end

-- Accumulate results
function Collector:__call(datum)
  table.insert(self.data, datum)
  -- Notify the search context that there are new results
  self.context.collector_update(self.data)
end

-- Result matchers
local Matcher = Node:new()
-- A matcher is called with a list of data and a pattern and calls its output with
-- {datum, match region} for each matching datum.
function Matcher:__call(_, _)
  error('__call(2) unimplemented for matcher ' .. self.name, 2)
end

-- Result display formatters
local Formatter = Node:new()
-- A formatter is called with a single datum and outputs a string
function Formatter:__call(_)
  error('__call(1) unimplemented for formatter ' .. self.name, 2)
end

types.Matcher = Matcher
types.Source = Source
types.Query = Query
types.Filter = Filter
types.Formatter = Formatter
types.Collector = Collector

return types
