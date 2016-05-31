require("busted")

local machine = require("statemachine")
local _ = require("luassert.match")._

describe("Lua state machine framework", function()
  describe("A stop light", function()
    local fsm
    local stoplight = {
      { name = 'warn',  from = 'green',  to = 'yellow' },
      { name = 'panic', from = 'yellow', to = 'red'    },
      { name = 'calm',  from = 'red',    to = 'yellow' },
      { name = 'clear', from = 'yellow', to = 'green'  }
    }

    before_each(function()
      fsm = machine.create({ initial = 'green', events = stoplight })
    end)

    it("should start as green", function()
      assert.are_equal(fsm.current, 'green')
    end)

    it("should not let you get to the wrong state", function()
      assert.is_false(fsm:panic())
      assert.is_false(fsm:calm())
      assert.is_false(fsm:clear())
    end)

    it("should let you go to yellow", function()
      assert.is_true(fsm:warn())
      assert.are_equal(fsm.current, 'yellow')
    end)

    it("should tell you what it can do", function()
      assert.is_true(fsm:can('warn'))
      assert.is_false(fsm:can('panic'))
      assert.is_false(fsm:can('calm'))
      assert.is_false(fsm:can('clear'))
    end)

    it("should tell you what it can't do", function()
      assert.is_false(fsm:cannot('warn'))
      assert.is_true(fsm:cannot('panic'))
      assert.is_true(fsm:cannot('calm'))
      assert.is_true(fsm:cannot('clear'))
    end)

    it("should support checking states", function()
      assert.is_true(fsm:is('green'))
      assert.is_false(fsm:is('red'))
      assert.is_false(fsm:is('yellow'))
    end)

    it("should fire callbacks", function()
      local fsm = machine.create({
        initial = 'green',
        events = stoplight,
        callbacks = {
          onbeforewarn = stub.new(),
          onleavegreen = stub.new(),
          onenteryellow = stub.new(),
          onafterwarn = stub.new(),
          onstatechange = stub.new(),
          onyellow = stub.new(),
          onwarn = stub.new()
        }
      })

      fsm:warn()

      assert.spy(fsm.onbeforewarn).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onleavegreen).was_called_with(_, 'warn', 'green', 'yellow')

      assert.spy(fsm.onenteryellow).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onafterwarn).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onstatechange).was_called_with(_, 'warn', 'green', 'yellow')

      assert.spy(fsm.onyellow).was_not_called()
      assert.spy(fsm.onwarn).was_not_called()
    end)

    it("should fire handlers", function()
      fsm.onbeforewarn = stub.new()
      fsm.onleavegreen = stub.new()
      fsm.onenteryellow = stub.new()
      fsm.onafterwarn = stub.new()
      fsm.onstatechange = stub.new()

      fsm.onyellow = stub.new()
      fsm.onwarn = stub.new()

      fsm:warn()

      assert.spy(fsm.onbeforewarn).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onleavegreen).was_called_with(_, 'warn', 'green', 'yellow')

      assert.spy(fsm.onenteryellow).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onafterwarn).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onstatechange).was_called_with(_, 'warn', 'green', 'yellow')

      assert.spy(fsm.onyellow).was_not_called()
      assert.spy(fsm.onwarn).was_not_called()
    end)

    it("should accept additional arguments to handlers", function()
      fsm.onbeforewarn = stub.new()
      fsm.onleavegreen = stub.new()
      fsm.onenteryellow = stub.new()
      fsm.onafterwarn = stub.new()
      fsm.onstatechange = stub.new()

      fsm:warn('bar')

      assert.spy(fsm.onbeforewarn).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.onleavegreen).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      
      assert.spy(fsm.onenteryellow).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.onafterwarn).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.onstatechange).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
    end)

    it("should fire short handlers as a fallback", function()
      fsm.onyellow = stub.new()
      fsm.onwarn = stub.new()

      fsm:warn()

      assert.spy(fsm.onyellow).was_called_with(_, 'warn', 'green', 'yellow')
      assert.spy(fsm.onwarn).was_called_with(_, 'warn', 'green', 'yellow')
    end)

    it("should cancel the warn event from onleavegreen", function()
      fsm.onleavegreen = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("should cancel the warn event from onbeforewarn", function()
      fsm.onbeforewarn = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("pauses when async is passed", function()
      fsm.onleavegreen = function(self, name, from, to)
        return fsm.ASYNC
      end
      fsm.onenteryellow = function(self, name, from, to)
        return fsm.ASYNC
      end

      local result = fsm:warn()
      assert.is_true(result)
      assert.are_equal(fsm.current, 'green')
      assert.are_equal(fsm.currentTransitioningEvent, 'warn')
      assert.are_equal(fsm.asyncState, 'warnWaitingOnLeave')

      result = fsm:transition(fsm.currentTransitioningEvent)
      assert.is_true(result)
      assert.are_equal(fsm.current, 'yellow')
      assert.are_equal(fsm.currentTransitioningEvent, 'warn')
      assert.are_equal(fsm.asyncState, 'warnWaitingOnEnter')

      result = fsm:transition(fsm.currentTransitioningEvent)
      assert.is_true(result)
      assert.are_equal(fsm.current, 'yellow')
      assert.is_nil(fsm.currentTransitioningEvent)
      assert.are_equal(fsm.asyncState, fsm.NONE)
    end)

    it("should accept additional arguments to async handlers", function()
      fsm.onbeforewarn = stub.new()
      fsm.onleavegreen = spy.new(function(self, name, from, to, arg)
        return fsm.ASYNC
      end)
      fsm.onenteryellow = spy.new(function(self, name, from, to, arg)
        return fsm.ASYNC
      end)
      fsm.onafterwarn = stub.new()
      fsm.onstatechange = stub.new()

      fsm:warn('bar')
      assert.spy(fsm.onbeforewarn).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.onleavegreen).was_called_with(_, 'warn', 'green', 'yellow', 'bar')

      fsm:transition(fsm.currentTransitioningEvent)
      assert.spy(fsm.onenteryellow).was_called_with(_, 'warn', 'green', 'yellow', 'bar')

      fsm:transition(fsm.currentTransitioningEvent)
      assert.spy(fsm.onafterwarn).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.onstatechange).was_called_with(_, 'warn', 'green', 'yellow', 'bar')
    end)

    it("should properly transition when another event happens during leave async", function()
      local tempStoplight = {}
      for _, event in ipairs(stoplight) do
        table.insert(tempStoplight, event)
      end
      table.insert(tempStoplight, { name = "panic", from = "green", to = "red" })
      
      local fsm = machine.create({
        initial = 'green',
        events = tempStoplight
      })

      fsm.onleavegreen = function(self, name, from, to)
        return fsm.ASYNC
      end

      fsm:warn()

      local result = fsm:panic()
      local transitionResult = fsm:transition(fsm.currentTransitioningEvent)

      assert.is_true(result)
      assert.is_true(transitionResult)
      assert.is_nil(fsm.currentTransitioningEvent)
      assert.are_equal(fsm.asyncState, fsm.NONE)
      assert.are_equal(fsm.current, 'red')
    end)

    it("should properly transition when another event happens during enter async", function()
      fsm.onenteryellow = function(self, name, from, to)
        return fsm.ASYNC
      end

      fsm:warn()

      local result = fsm:panic()

      assert.is_true(result)
      assert.is_nil(fsm.currentTransitioningEvent)
      assert.are_equal(fsm.asyncState, fsm.NONE)
      assert.are_equal(fsm.current, 'red')
    end)

    it("should properly cancel the transition if asked", function()
      fsm.onleavegreen = function(self, name, from, to)
        return fsm.ASYNC
      end

      fsm:warn()
      fsm:cancelTransition(fsm.currentTransitioningEvent)

      assert.is_nil(fsm.currentTransitioningEvent)
      assert.are_equal(fsm.asyncState, fsm.NONE)
      assert.are_equal(fsm.current, 'green')

      fsm.onleavegreen = nil
      fsm.onenteryellow = function(self, name, from, to)
        return fsm.ASYNC
      end

      fsm:warn()
      fsm:cancelTransition(fsm.currentTransitioningEvent)

      assert.is_nil(fsm.currentTransitioningEvent)
      assert.are_equal(fsm.asyncState, fsm.NONE)
      assert.are_equal(fsm.current, 'yellow')
    end)

    it("todot generates dot file (graphviz)", function()
      assert.has_no_error(function()
        fsm:todot('stoplight.dot')
      end)
      assert.is_equal(io.open('stoplight.dot'):read('*a'), io.open('stoplight.dot.ref'):read('*a'))
    end)
  end)

  describe("A monster", function()
    local fsm
    local monster = {
      { name = 'eat',  from = 'hungry',                                to = 'satisfied' },
      { name = 'eat',  from = 'satisfied',                             to = 'full'      },
      { name = 'eat',  from = 'full',                                  to = 'sick'      },
      { name = 'rest', from = {'hungry', 'satisfied', 'full', 'sick'}, to = 'hungry'    }
    }

    before_each(function()
      fsm = machine.create({ initial = 'hungry', events = monster })
    end)

    it("can eat unless it is sick", function()
      assert.are_equal(fsm.current, 'hungry')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'satisfied')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'full')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'sick')
      assert.is_false(fsm:can('eat'))
    end)

    it("can always rest", function()
      assert.are_equal(fsm.current, 'hungry')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'satisfied')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'full')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'sick')
      assert.is_true(fsm:can('rest'))
      fsm:rest()
      assert.are_equal(fsm.current, 'hungry')
    end)
  end)
end)
