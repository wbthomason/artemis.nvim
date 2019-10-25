-- Common types
local types = {}

-- Define a data source
local Source = {}
function Source:new(name)
  local source = {
    name = name,
    sink = nil
  }

  setmetatable(source, self)
  return source
end

function Source:start()
  error('start() unimplemented for source ' .. self.name, 2)
end

function Source:connect(filter)
  self.sink = filter
end

-- Define a search graph
local Graph = {}
function Graph:new(sink, ...)
  local graph = {
    sources = {...},
    sink = sink
  }
  
  setmetatable(graph, self)
  return graph
end

types.Source = Source
types.Graph = Graph

return types
