local machine = {}
machine.__index = machine


local function create_transition(name, to)
  return function(self)
    if self:can(name) then
      self.current = to
      if self["on" .. name] then self["on" .. name](self, name, nil, to) end
      return true
    end
    return false
  end
end


function machine.create(options)
  assert(options.events)

  local fsm = {}
  setmetatable(fsm, machine)

  fsm.current = options.initial or 'none'
  fsm.events = options.events

  for _, event in ipairs(options.events) do
    fsm[event.name] = create_transition(event.name, event.to)
  end

  return fsm
end

function machine:is(state)
  return self.current == state
end

function machine:can(e)
  for _, event in ipairs(self.events) do
    if event.name == e and self.current == event.from then
      return true
    end
  end
  return false
end

function machine:cannot(e)
  return not self:can(e)
end

return machine
