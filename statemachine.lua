local machine = {}
machine.__index = machine


local function create_transition(name)
  return function(self, ...)
    local can, to = self:can(name)

    if can then
      local from = self.current

      if self["onbefore" .. name] then 
        local cancel = self["onbefore" .. name](self, name, from, to, ...)
        if cancel == false then
          return false
        end
      end

      if self["onleave" .. from] then 
        local cancel = self["onleave" .. from](self, name, from, to, ...)
        if cancel == false then
          return false
        end
      end

      self.current = to

      if self["on" .. to] then 
        self["on" .. to](self, name, from, to, ...)
      end

      if self["on" .. name] then 
        self["on" .. name](self, name, from, to, ...)
      end

      if self.onstatechange then 
        self.onstatechange(self, name, from, to, ...)
      end

      return true
    end

    return false
  end
end

local function add_to_map(map, event)
  if type(event.from) == 'string' then
    map[event.from] = event.to
  else
    for _, from in ipairs(event.from) do
      map[from] = event.to
    end
  end
end

function machine.create(options)
  assert(options.events)

  local fsm = {}
  setmetatable(fsm, machine)

  fsm.current = options.initial or 'none'
  fsm.events = {}
  fsm.options = options

  for _, event in ipairs(options.events) do
    local name = event.name
    fsm[name] = fsm[name] or create_transition(name)
    fsm.events[name] = fsm.events[name] or { map = {} }
    add_to_map(fsm.events[name].map, event)
  end

  return fsm
end

function machine:is(state)
  return self.current == state
end

function machine:can(e)
  local event = self.events[e]
  local to = event and event.map[self.current]
  return to ~= nil, to
end

function machine:cannot(e)
  return not self:can(e)
end

function machine:todot(filename)
  local dotfile = io.open(filename,'w')
  dotfile:write('digraph {\n')
  local transition = function(event,from,to)
    dotfile:write(string.format('%s -> %s [label=%s];\n',from,to,event))
  end
  for _, event in pairs(self.options.events) do
    if type(event.from) == 'table' then
      for _, from in ipairs(event.from) do
        transition(event.name,from,event.to)
      end
    else
      transition(event.name,event.from,event.to)
    end
  end
  dotfile:write('}\n')
  dotfile:close()
end


return machine
