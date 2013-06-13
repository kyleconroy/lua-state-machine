local machine = {}
machine.__index = machine


local function create_transition(name)
  return function(self, ...)
    local can, to = self:can(name)

    if can then
      local from = self.current
      
      local onbefore = self["onbefore" .. name]
      if onbefore then 
        local cancel = onbefore(self, name, from, to, ...)
        if cancel == false then
          return false
        end
      end

      local onleave = self["onleave" .. from]
      if onleave then 
        local cancel = onleave(self, name, from, to, ...)
        if cancel == false then
          return false
        end
      end

      self.current = to

      local onenter = self["onenter" .. to] or self["on" .. to]
      if onenter then 
        onenter(self, name, from, to, ...)
      end

      local onafter = self["onafter" .. name] or self["on" .. name]
      if onafter then 
        onafter(self, name, from, to, ...)
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

  for _, event in ipairs(options.events) do
    local name = event.name
    fsm[name] = fsm[name] or create_transition(name)
    fsm.events[name] = fsm.events[name] or { map = {} }
    add_to_map(fsm.events[name].map, event)
  end

  if options.callbacks then
    for name, callback in pairs(options.callbacks) do
      fsm[name] = callback
    end
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

return machine
