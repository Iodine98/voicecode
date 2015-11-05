CustomGrammar = require './parser/customGrammar'

class Commands
  instance = null
  history = {}
  constructor: ->
    return instance if instance?
    instance = @
    # Events.on 'chainPreprocessed', (commands) => @history commands
    @mapping = {}
    @renamings = []
    @context = "global"
    @initialized = false
    @commandEditsFrom = 'code'
    @conditionalModules = {}
    @lastIndividualCommand = null
    @lastFullCommand = null
    @subcommandIndex = 0
    @repetitionIndex = 0
    @currentUndoByDeletingCount = 0
    @aggregateUndoByDeletingCount = 0
    @previousUndoByDeletingCount = 0
    @primaryGrammarTypes = [
      "numberCapture"
      "numberRange"
      "textCapture"
      "individual"
      "singleSearch"
      "oneArgument"
      "custom"
    ]
    @keys =
      oneArgument: []
      oneArgumentContinuous: []
      singleSearch: []
      singleSearchContinuous: []
      individual: []
      individualContinuous: []
      numberCapture: []
      numberCaptureContinuous: []
      numberRange: []
      numberRangeContinuous: []
      textCapture: []
      textCaptureContinuous: []
      custom: []
      customContinuous: []
      repeater: []
      findable: []
    @delayedEditFunctions = []
    @monitoringMouseToCancelSpacing = true

  initialize: () ->
    @performCommandEdits()
    Events.on 'enableCommand', (commandName) => @enable commandName
    Events.on 'disableCommand', (commandName) => @disable commandName

    Events.on 'userAssetsLoaded', =>
      @commandEditsFrom = 'user'
      # @performCommandEdits()

    Events.on 'EnabledCommandsManagerSettingsProcessed', =>
      @commandEditsFrom = 'settings'
      @performCommandEdits()

  getCurrentNameFor: (commandName) ->
    (_.pluck @renamings, {from: commandName})?.to || commandName

  validate: (command, options, editType) ->
    validated = true
    switch editType
      when 'commandCreated'
        if @mapping[command]?
          if options.action?
            if options.action.toString() is @mapping[command].action.toString()
              validated = false # action is the same
              break
          # else
          #   error 'commandHasNoAction', command, "Command #{command} has no action."
          #   validated = false
          warning 'commandOverwritten', command, "Command '#{command}' overwritten by command with a same name"
        if options.rule?.match(/\(.*?\d+.*?\)/g)?
          error 'commandValidationError', command, 'Please don\'t use integers in list names'
          validated = false
      when 'commandMisspellingsAdded'
        if _.isEmpty _.difference options, command.misspellings
          validated = false
      when 'commandBeforeAdded'
        if @mapping[command.namespace]?.before?
          unless @mapping[command.namespace].before[options.name]?
            # everything is good if such 'before' does not exist yet
            break
          options.action = options.action.toString()
          aggregate = _.map command.before, (action) ->
            action.toString() isnt options.action
          validated = not _.isEmpty _.compact aggregate
      when 'commandAfterAdded'
        if @mapping[command.namespace]?.after?
          unless @mapping[command.namespace].before[options.name]?
            break
          options = options.toString()
          aggregate = _.map command.after, (action) ->
            action.toString() isnt options
          validated = not _.isEmpty _.compact aggregate
      when 'commandEnabled'
        if command.enabled is true
          validated = false
      when 'commandNameChanged'
        if _.findWhere(@renamings, {to: options})?
          validated = false

    if not validated and @shouldEmitValidationFailed(editType, command)
      emit 'commandValidationFailed', {command, options, editType}

    return validated

  enable: (name) ->
    @edit name, 'commandEnabled', null, (command) ->
      command.enabled = true
      command

  disable: (name) ->
    @edit name, 'commandDisabled', null, (command) ->
      return false if command.enabled is false
      command.enabled = false
      command

  create: (name, options) ->
    if typeof name is "object"
      _.each name, (options, name) =>
        @create name, options
      return

    validated = @validate name, options, 'commandCreated'
    return if not validated
    @mapping[name] = @normalizeOptions name, options
    if options.enabled is true
      @enable name

  createWithDefaults: (defaults, options) ->
    _.each options, (value, key) =>
      command = _.extend {}, defaults, value
      command.enabled = true
      @create key, command

  createDisabled: (name, options) ->
    if typeof name is "object"
      _.each name, (value, key) =>
        @create key, value
      return
    options.enabled = false
    @create name, options

  createDisabledWithDefaults: (defaults, options) ->
    for key, value of options
      command = _.extend {}, defaults, value
      command.enabled = false
      @create key, command

  edit: (name, editType, edition, callback) ->
    @delayedEditFunctions.push {name, editType, callback, edition}

  get: (name) ->
    isRenamed = _.findWhere @renamings, {from: name}
    if isRenamed?
      log 'commandRenamedReference', isRenamed, "#{isRenamed.from} => #{isRenamed.to}"
      return @mapping[isRenamed.to]
    @mapping[name]

  # 4 debugging
  shouldEmitValidationFailed: (editType, command) ->
    if editType is 'commandEnabled'
      return false
    return true

  performCommandEdits: ->
    _.each @delayedEditFunctions, ({name, callback, editType, edition}) =>
      console.log name, editType
      command = @get name

      isRenamed = _.findWhere @renamings, {from: name}
      if isRenamed?
        name = isRenamed.to

      if command?
        return if not @validate command, edition, editType
        try
          result = callback command
        catch e
          debug {command, editType, edition, e}
        if _.isObject result
          @mapping[name] = @normalizeOptions name, result
        emit editType, !!result, name
      else
        # allow addressing nonexistent commands while loading from settings
        # as we are not fully initialized yet
        if not isRenamed?
          if @commandEditsFrom is 'settings'
            @edit name, editType, callback # let us try again in the next iteration
          else
            error 'commandNotFound', name
    @delayedEditFunctions = []

  override: (name, action) ->
    error 'deprecation', "Failed overriding '#{name}'.
    Commands.override is deprecated. Use Commands.extend"

  extend: (name, edition) ->
    warning 'deprecation', "Failed extending '#{name}'.
    Commands.extend is deprecated. Use Commands.before"
    @before name, edition

  before: (commandName, beforeName, edition) ->
    if _.isFunction beforeName
      error 'commandValidationFailed', commandName,
      "Commands.before API changed.\n
      Please provide a unique identifier for your method as the second parameter: \n
      Commands.before '#{commandName}', 'my-#{commandName}-before', (input, context) -> doMagic()"
      return
    @edit commandName, 'commandBeforeAdded', {name: beforeName, action: edition}, (command) ->
      command.before ?= {}
      command.before[beforeName] = edition
      command

  after: (commandName, afterName, edition) ->
    if _.isFunction afterName
      error 'commandValidationFailed', commandName,
      "Commands.after API changed.\n
      Please provide a unique identifier for your method as the second parameter: \n
      Commands.after '#{commandName}', 'my-#{commandName}-after', (input, context) -> doMagic()"
      return
    @edit commandName, 'commandAfterAdded', {name: afterName, action: edition}, (command) ->
      command.after ?= {}
      command.after[afterName] = edition
      command

  addMisspellings: (name, edition) ->
    @edit name, 'commandMisspellingsAdded', edition, (command) ->
      command.misspellings ?= []
      command.misspellings = command.misspellings.concat edition
      command

  addAliases: (name, aliases) ->
    error 'deprecation',
    "Failed adding aliases to '#{name}'.
    'addAliases' has been renamed to 'addMisspellings'. "

  changeName: (name, newName) ->
    @edit name, 'commandNameChanged', newName, (command) ->
      if _.findWhere(@renamings, {to: name})?
        # renaming something that has already been renamed
        # removing previous renaming reference, allowing swapping command names
        warning 'commandOverwritten', name, "Command #{name} overwritten by renaming twice"
        @renamings = _.reject @renamings, ({to}) -> to is name

      if @mapping[newName]?
        warning 'commandOverwritten', newName, "Command #{newName} overridden by renaming"

      command.namespace = newName
      command.misspellings = []
      @mapping[newName] = command
      @renamings.push {from: name, to: newName}
      delete @mapping[name]
      true

  normalizeOptions: (name, options) ->
    options.namespace = name
    options.enabled ?= true
    options.grammarType ?= 'individual'
    options.kind ?= 'action'

    type = options.grammarType
    if type in @primaryGrammarTypes
      unless name in @keys[type]
        @keys[type].push name
      unless options.continuous is false
        unless name in @keys[type + "Continuous"]
          @keys[type + "Continuous"].push name

    if options.findable?
      @keys.findable.push name

    if options.repeater?
      @keys.repeater.push name

    if options.rule?
      # try
      options.grammar = new CustomGrammar(options.rule, options.variables)
      # catch e
      #   console.log "error parsing custom grammar for command: #{key}"
      #   console.log e
    options

module.exports = new Commands
