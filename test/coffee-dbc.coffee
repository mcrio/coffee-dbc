should = require('chai').should()
dbc = require '../src/coffee-dbc'


describe 'Design By Contract', ->


  describe '#class', ->

    it 'should return a class', ->
      Cls = dbc.class ->
      new Cls

    it 'should allow for a constructor', ->
      Cls = dbc.class ->
        constructor: (@x) ->
      obj = new Cls(24)

    it 'should not allow direct access to instance variables', ->
      Cls = dbc.class ->
        constructor: (@x) ->
      obj = new Cls(24)
      should.not.exist obj.x


  describe 'Queries', ->

    it 'should be possible', ->
      Cls = dbc.class ->
        queries:
          x: -> 24
      obj = new Cls
      obj.x().should.equal 24

    it 'should have access to instance variables', ->
      Cls = dbc.class ->
        constructor: (@x) ->
        queries: x: -> @x * 2
      new Cls(5).x().should.equal 10


  describe 'Commands', ->

    it 'should be possible and have access to instance variables', ->
      Cls = dbc.class ->
        constructor: -> @internal = 0
        queries: x: -> @internal
        commands:
          addToX: (x) ->
            do: (x) -> @internal += x
      obj = new Cls
      obj.x().should.equal 0
      obj.addToX(33)
      obj.x().should.equal 33
      obj.addToX(15)
      obj.x().should.equal 48

    it 'should be forced to return undefined', ->
      Cls = dbc.class ->
        commands:
          justChangeSomething: ->
            do: -> return 'a value'
      should.not.exist new Cls().justChangeSomething()

    it 'should allow for preconditions ("require")', ->
      Cls = dbc.class ->
        constructor: (@internal) ->
        queries: name: -> @internal
        commands:
          setName: (name) ->
            require:
              nameIsNotLongerThan10Characters: -> @name.length <= 10
            do: (name) -> @internal = name
      obj = new Cls 'Felix'
      (-> obj.setName '1234567890').should.not.throw dbc.ContractException
      (-> obj.setName '12345678901').should.throw dbc.ContractException, \
        "Contract 'setName.require.nameIsNotLongerThan10Characters' was broken"
      obj.name().should.not.equal '12345678901'
      obj.name().should.equal '1234567890'

    it 'should allow for postconditions ("ensure")'


  describe 'Class Invariant', ->

    it 'should be checked after construction', ->
      Cls = dbc.class ->
        constructor: (@name) ->
        invariant:
          nameIsAString: -> typeof @new.name == 'string'
      (-> new Cls 5).should.throw dbc.ContractException, \
        "Contract 'invariant.nameIsAString' was broken"
      (-> new Cls 5).should.not.throw \
        "Contract 'nameIsAString' was broken"

    it 'should provide access to instance variables', ->
      Cls = dbc.class ->
        constructor: (@x) ->
        invariant:
          hasX: -> @new.x?
      (-> new Cls 123).should.not.throw dbc.ContractException
      (-> new Cls).should.throw dbc.ContractException

    it 'should check for correct values', ->
      Cls = dbc.class ->
        constructor: (@x) ->
        invariant:
          xIsSmallerThan12: -> @new.x < 12
      (-> new Cls 5).should.not.throw dbc.ContractException
      (-> new Cls 15).should.throw dbc.ContractException

    it 'should be checked after every command call', ->
      Cls = dbc.class ->
        constructor: (@name) ->
        invariant:
          nameIsAString: -> typeof @new.name == 'string'
        commands:
          setName: (name) ->
            do: (name) -> @name = name
      obj = null
      (-> new Cls).should.throw dbc.ContractException
      (-> new Cls 5).should.throw dbc.ContractException
      (-> obj = new Cls 'Heinz').should.not.throw dbc.ContractException
      (-> obj.setName 5).should.throw dbc.ContractException, /nameIsAString/


  describe '#getFnArgNames', ->

    it 'should get the list of argument names', ->
      should.not.exist dbc.getFnArgNames ->
      (dbc.getFnArgNames (alabama) ->).should.deep.equal ['alabama']
      (dbc.getFnArgNames (a, b, c = 5) ->).should.deep.equal ['a', 'b', 'c']
      should.not.exist dbc.getFnArgNames (a, b, c...) ->  # CoffeeScript uses arguments here
