require("busted")

local machine = require("statemachine")

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

    it("should cancel the warn event", function()
      fsm.onleavegreen = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("should cancel the warn event", function()
      fsm.onbeforewarn = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("should accept other arguments", function()
      fsm.onstatechange = function(self, name, from, to, foo)
        self.foo = foo
      end

      fsm:warn("bar")

      assert.are_equal(fsm.foo, 'bar')
    end)

    it("should fire the onstatechange handler", function()
      fsm.onstatechange = function(self, name, from, to) 
        self.name = name
        self.from = from
        self.to = to
      end

      fsm:warn()

      assert.are_equal(fsm.name, 'warn')
      assert.are_equal(fsm.from, 'green')
      assert.are_equal(fsm.to, 'yellow')
    end)

    it("should fire the onenteryellow handler", function()
      fsm.onenteryellow = function(self, name, from, to) 
        self.name = name
        self.from = from
        self.to = to
      end

      fsm:warn()

      assert.are_equal(fsm.name, 'warn')
      assert.are_equal(fsm.from, 'green')
      assert.are_equal(fsm.to, 'yellow')
    end)


    it("should fire the onwarn handler", function()
      fsm.onwarn = function(self, name, from, to) 
        self.name = name
        self.from = from
        self.to = to
      end

      fsm:warn()

      assert.are_equal(fsm.name, 'warn')
      assert.are_equal(fsm.from, 'green')
      assert.are_equal(fsm.to, 'yellow')
    end)

    it("should fire the onafterwarn handler", function()
      fsm.onafterwarn = function(self, name, from, to) 
        self.name = name
        self.from = from
        self.to = to
      end

      fsm:warn()

      assert.are_equal(fsm.name, 'warn')
      assert.are_equal(fsm.from, 'green')
      assert.are_equal(fsm.to, 'yellow')
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
