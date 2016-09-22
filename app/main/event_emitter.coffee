path = require 'path'
utilities = require 'util'

class EventEmitter extends require('events').EventEmitter
  instance = null
  constructor: ->
    return instance if instance?
    process.stdout.write = (chunk, encoding, next = null) =>
      @stdout _.truncate(chunk, {length: 50}), chunk
      next?()
    process.stderr.write = (chunk, encoding, next = null) =>
      @stderr _.truncate(chunk, {length: 50}), chunk
      next?()

    @setMaxListeners 300
    instance = @
    @frontendSubscriptions = {}
    @suppressedLogEntries = [
      'dragonInterfaceData'
      'willParsePhrase'
    ]
    @subscribeToEvents()
    if developmentMode
      @_logEvents = developmentMode
      @suppressedLogEntries = [
        'dragonInterfaceData'
        'apiCreated'
        # 'deprecation'
        'implementationWillExecute'
        'packageSettingsChanged'
        'enableCommand'
        'commandCreated'
        'commandEnabled'
        'windowCreated'
        'implementationCreated'
        # 'commandOverwritten'
        'commandAfterAdded'
        'commandBeforeAdded'
        'commandMisspellingsAdded'
        'commandSpokenChanged'
        'charactersTyped'
        'historicChainCreated'
        'historicChainLinkCreated'
        'assetEvent'
        'assetEvaluated'
        'assetsLoaded'
        'userAssetEvent'
        'userAssetsLoading'
        'userAssetsLoaded'
        'userAssetEvaluated'
        'mouse.leftClick'
        'packageReady'
        'userAssetEvaluated'
        'userAssetEvent'
        'packageAssetEvaluated'
        'packageAssetEvent'
        # 'commandEditsPerformed'
        'userCodeCommandEditsPerformed'
        'enabledCommandsCommandEditsPerformed'
        'slaveModeEnableAllCommandsCommandEditsPerformed'
        'packageCreated'
        'assetEvent'
        # 'commandValidationFailed'
        # 'commandValidationError'
        # 'chainParsed'
        'chainPreprocessed'
        # 'chainWillExecute'
        'commandDidExecute'
        'chainDidExecute'
        'commandNotFound'
        # 'eventMonitorStarted'
        'dragonStarted'
        # 'packageAssetEvent'
        'currentApplicationWillChange'
        # 'systemEventHandler'
        # 'currentApplicationChanged'
        'notUndoable'
        /.*PackageCreated$/
        /.*PackageReady$/
        /.*SettingsChanged$/
      ]
    @suppressedLogEntries = _.map @suppressedLogEntries, (entry) ->
      if _.isString entry
        new RegExp "^#{entry}$"
      else
        entry

  logEvents: (setter = null)->
    if setter?
      @_logEvents = setter
    @_logEvents

  subscribeToEvents: ->
    @on 'logEvents', @logEvents.bind(@)

  frontendOn: (event, callback) ->
    # this is needed because only enumerable properties are accessible
    # via remote module i.e every object needs to be flattened
    switch event
      when 'implementationCreated'
        _callback = ->
          implementations = _.keys arguments[0].implementations
          commandId = arguments[0].id
          callback.call null, {implementations, commandId}
    # @frontendSubscriptions[event] ?= []
    # @frontendSubscriptions[event].push _callback or callback
    @on event, (_callback or callback)

  frontendClearSubscriptions: ->
    _.each @frontendSubscriptions, (callbacks, event) =>
      @unsubscribe event, callbacks
    @frontendSubscriptions = {}

  # frontendEmit: (event) ->
  #   debug arguments
  #   debug @frontendSubscriptions
  #   @_emit.apply @, arguments
  #   return unless @frontendSubscriptions[event]?
  #   _.each @frontendSubscriptions[event], (callback) =>
  #     callback.apply @, arguments[1...]

  unsubscribe: (event, callback) ->
    if _.isArray callback
      return _.each callback, (c) => @unsubscribe event, c
    @removeListener event, callback

  on: (event, callback) ->
    if _.isArray event
      _.map event, (e) =>
        @on e, callback
      return
    super

  once: (event, callback) ->
    if _.isArray event
      _.map event, (e) =>
        @once e, callback
      return
    super

  removeListener: (event, callback) ->
    if _.isArray event
      _.map event, (e) =>
        @removeListener e, callback
      return
    super

  logger: (entry) ->
    unless @radioSilence
      process.nextTick =>
        entry.timestamp = process.hrtime()
        @emit 'logger', entry

  debug: (event) ->
    args = _.toArray arguments
    event = 'debug'
    if _.isString args[0]
      event = args[0]
    else
      args.unshift null
    args[0] = {type: 'debug', event}
    @_emit.apply @, args

  error: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'error', event}
    @_emit.apply @, args

  stderr: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'stderr', event}
    @_emit.apply @, args

  stdout: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'stdout', event}
    @_emit.apply @, args

  log: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'log', event}
    @_emit.apply @, args

  warning: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'warning', event}
    @_emit.apply @, args

  notify: (event) ->
    args = _.toArray arguments
    args[0] = {type: 'notify', event}
    @_emit.apply @, args

  _emit: ({event, type}) ->
    event ?= arguments[0] if _.isString arguments[0]
    event ?= 'app'
    type ?= 'event'
    args = _.toArray arguments
    if @logEvents() or type in ['stdout', 'stderr']
      unless (_.some @suppressedLogEntries
      , (suppressed) -> suppressed.test event)
        @logger
          type: type
          event: event
          args: (utilities.inspect args[1..]
            , {depth: 5, color: false}).replace "\\n", "\n"
    else
      unless type in ['event', 'mutate', 'debug']
        @logger
          type: type
          # event: args[2] || "#{event} is missing a human readable message"
          event: event
          args: (utilities.inspect args[1..]
          , {depth: 5, color: false}).replace "\\n", "\n"

    unless type in ['mutate', 'debug', 'stdout', 'stderr']
      args[0] = event
      @emit.apply @, args

  mutate: (event, container={}) ->
    args = _.toArray arguments
    args[0] = {type: 'mutate', event}
    @_emit.apply @, args

    return container unless events = @_events[event]
    container.continue = true
    if _.isFunction events
      events = [events]
    _.reduce events, (container={}, event) ->
      return container unless container.continue
      container = event container
      container
    , container

Events = new EventEmitter
global.debug = _.bind Events.debug, Events
global.emit = _.bind Events._emit, Events
global.error = _.bind Events.error, Events
global.log = _.bind Events.log, Events
global.warning = _.bind Events.warning, Events
global.notify = _.bind Events.notify, Events
global.mutate = _.bind Events.mutate, Events
global.unsubscribe = _.bind Events.unsubscribe, Events
module.exports = Events

global.mutationNotifier = (target, event, args, deep = false) ->
  new Proxy target,
    set: (target, property, value, receiver) ->
      if value isnt target[property]
        payload = _.assign {}, args, {
          property,
          oldValue: target[property],
          value: value
        }
        process.nextTick ->
          emit event, payload
        # emit "#{event}Set", payload
        # emit "#{event}#{target}", payload
        # emit "#{event}#{target}Set", payload
        if deep and _.isObjectLike value
          value = mutationNotifier value, event, args, true
      Reflect.set target, property, value, receiver
    deleteProperty: (target, property) ->
      payload = _.assign {}, args, {
        property,
        oldValue: target[property],
        value: undefined
      }
      process.nextTick ->
        emit event, payload

      # emit "#{event}Delete", payload
      # emit "#{event}#{target}", payload
      # emit "#{event}#{target}Delete", payload
      Reflect.deleteProperty target, property
