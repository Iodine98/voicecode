class HistoryController
  previousContext = null
  amnesia = false
  activeChains = 0

  constructor: ->
    @history = {}

    Events.on 'chainWillExecute', =>
      activeChains++
      if activeChains is 1
        @startNewChain()

    Events.on 'chainDidExecute', =>
      activeChains--
      @history[previousContext][0] = _.compact @history[previousContext][0]
      if _.isEmpty @history[previousContext][0]
        @forgetChain 0

    Events.on 'commandDidExecute', ({link}) =>
      command = Commands.get link.command
      unless command.bypassHistory?(link.context)
        currentContext = @getCurrentContext()
        if previousContext isnt currentContext
          @startNewChain currentContext
        # coffee script is stupid, why make the extra 'arg' variable?
        delete arguments[0].link.context
        unless amnesia
          @history[currentContext][0].unshift _.pick link, ['command', 'arguments']

  forgetChain: (offset) ->
    delete @history[previousContext][offset]
    @history[previousContext] = _.values _.compact @history[previousContext]

  getCommands: (chainOffset = 0, offset = 0, count = 1, context = null) ->
    context ?= @getCurrentContext()
    if chainOffset is 0 and @getChainLength() is 0
      chainOffset++
    try
      return @history[context][chainOffset][offset...count]
    catch
      return []

  getChain: (offset = 0, context = null) ->
    context ?= @getCurrentContext()
    chain = @history[context][offset]
    chain = _.cloneDeep @history[context][offset]
    chain.reverse()

  hasAmnesia: (yesNo) ->
    amnesia = yesNo

  startNewChain: (context = null) ->
    context ?= @getCurrentContext()
    @history[context] ?= []
    @history[context].unshift []
    previousContext = context

  doChainMaintenance: ->
    # delete old stuff
    # dump to disk?

  getCurrentContext: ->
    Actions.currentApplication().name

  getChainLength: (offset = 0) ->
    try
      return @history[@getCurrentContext()][offset].length
    catch
      return 0

module.exports = new HistoryController
