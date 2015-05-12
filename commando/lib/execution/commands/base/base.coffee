@Commands ?= {}
Commands.mapping = {}
Commands.history = []
Commands.context = "global"
Commands.conditionalModules = {}
Commands.lastIndividualCommand = null
Commands.lastFullCommand = null
Commands.subcommandIndex = 0
Commands.repetitionIndex = 0
Commands.currentUndoByDeletingCount = 0
Commands.aggregateUndoByDeletingCount = 0
Commands.previousUndoByDeletingCount = 0
Commands.primaryGrammarTypes = [
  "numberCapture"
  "textCapture"
  "individual"
  "singleSearch"
  "oneArgument"
]
Commands.keys =
  oneArgument: []
  oneArgumentContinuous: []
  singleSearch: []
  singleSearchContinuous: []
  individual: []
  individualContinuous: []
  numberCapture: []
  numberCaptureContinuous: []
  textCapture: []
  textCaptureContinuous: []
  repeater: []
  findable: []

Commands.create = (name, options) ->
  if typeof name is "string"
    options.enabled = true
    Commands.mapping[name] = options
  else if typeof name is "object"
    _.extend Commands.mapping, name
    for key in _.keys(name)
      Commands.mapping[key].enabled = true

Commands.createDisabled = (name, options) ->
  if typeof name is "string"
    Commands.mapping[name] = options
  else if typeof name is "object"
    _.extend Commands.mapping, name

Commands.override = (name, callback) ->
  Commands.mapping[name].override = callback

Commands.addAliases = (key, aliases) ->
  Commands.mapping[key].aliases ?= []
  Commands.mapping[key].aliases = Commands.mapping[key].aliases.concat aliases

Commands.changeName = (old, newName) ->
  Commands.mapping[newName] = Commands.mapping[old]
  delete Commands.mapping[old]

Commands.loadConditionalModules = ->
  _.each Commands.mapping, (value, key) ->
    enabled = !!Enables.findOne(name: key)?.enabled
    Commands.mapping[key].enabled = Commands.mapping[key].enabled or enabled

    type = value.grammarType or "individual"
    
    if type in Commands.primaryGrammarTypes
      Commands.keys[type].push key
      unless value.continuous is false
        Commands.keys[type + "Continuous"].push key

    if value.findable?
      Commands.keys.findable.push key

    if value.repeater?
      Commands.keys.repeater.push key


class Commands.Base
  constructor: (@namespace, @input) ->
    @info = Commands.mapping[@namespace] 
    @kind = @info.kind or "action"
  transform: ->
    Transforms[@info.transform]
  generate: ->
    funk = switch @kind
      when "action"
        action = @info.action
        input = @input
        -> action.call(@, input)
      when "historic"
        action = @info.action
        input = @input
        context =
          lastFullCommand: Commands.lastFullCommand
          lastIndividualCommand: Commands.lastIndividualCommand
          repetitionIndex: Commands.repetitionIndex
        -> action.call(@, context, input)
      when "text"
        if @input?.length or @info.transformWhenBlank
          transformed = @applyTransform(@input)
          prefix = @info.prefix or ""
          suffix = @info.suffix or ""
          -> @string([prefix, transformed, suffix].join(''))
          # Scripts.makeTextCommand([prefix, transformed, suffix].join(''))
        else
          fallback = @info.fallbackService
          transform = @info.transform
          -> 
            if fallback?
              switch @currentApplication()
                when "Atom"
                  @runAtomCommand "transformSelectedText", transform
                else
                  if @isTextSelected()
                    contents = @getSelectedText()
                    transformed = SelectionTransformer[transform](contents)
                    @string transformed
            # Commands.incomingSelectionHandler = SelectionTransformer[transform]
            # @clickServiceItem("send-selection-to-voicecode")
              # @clickServiceItem(fallback)
      when "word"
        transformed = Transforms.identity([@info.word].concat(@input or []))
        -> @string(transformed)
      when "combo"
        combined = _.map(@info.combo, (subCommand) ->
          command = new Commands.Base(subCommand)
          command.generate()
        )
        ->
          _.each combined, (callback) ->
           if callback?
             callback.call(Actions)

    if @info.override?
      override = @info.override
      input = @input
      -> override.call(@, input, funk)
    else        
      funk
      # when "number"
      #   preCommand = if @info.padLeft
      #     Scripts.spacePad()
      #   else
      #     ""
      #   [preCommand, Scripts.makeTextCommand "#{@input}"].join("\n")
      # when "action"
      #   if @info.contextualActions?
      #     scopeCases = []
      #     me = @
      #     _.each @info.contextualActions, (scenarioInfo, scenarioName) ->
      #       scopeCases.push(
      #         requirements: scenarioInfo.requirements
      #         generated: Scripts.joinActionCommands(scenarioInfo.actions, me.input)
      #       )
      #     fallback = if @actions
      #       Scripts.joinActionCommands(@actions, @input)
      #     else
      #       Scripts.outOfContext(@namespace)
            
      #     Scripts.applicationScope scopeCases, fallback
      #   else
      #     if @actions?.length
      #       Scripts.joinActionCommands(@actions, @input)

      # when "modifier"
      #   @makeModifierCommand @input
  applyTransform: (textArray) ->
    transform = @transform()
    @transform()(textArray)
  repeatCount: ->
    n = parseInt(@input)
    if n? and n > 1
      n
    else
      1
  getTriggerPhrase: () ->
    if @info.triggerPhrase is undefined
      @namespace
    else
      @info.triggerPhrase
  getTriggerScopes: ->
    @info.triggerScopes or [@info.triggerScope or "Global"]
  needsDragonCommand: ->
    @info.needsDragonCommand != false
  generateFullCommand: () ->
    space = @info.namespace or @namespace
    # if @info.contextSensitive
    """
    on srhandler(vars)
      set dictatedText to (varText of vars)
      set toExecute to "curl http://commando:5000/parse --data-urlencode space=\\\"#{space}\\\"" & " --data-urlencode phrase=\\\"" & dictatedText & "\\\""
      do shell script toExecute
    end srhandler
    """
    # else
    #   """
    #   on srhandler(vars)
    #     set dictatedText to (varText of vars)
    #     if dictatedText = "" then
    #     #{commandText}
    #     set toExecute to "curl http://commando:5000/miss --data-urlencode space=\\\"#{space}\\\""
    #     do shell script toExecute
    #     else
    #     set toExecute to "curl http://commando:5000/parse --data-urlencode space=\\\"#{space}\\\"" & " --data-urlencode phrase=\\\"" & dictatedText & "\\\""
    #     do shell script toExecute
    #     end if
    #   end srhandler
    #   """
  generateFullCommandWithDigest: ->
    script = @generateFullCommand()
    digest = @digest()
    """
    -- #{digest}
    #{script}
    """
  generateDragonBody: ->
    space = @info.namespace or @namespace
    # """
    # curl http://commando:5000/parse --data-urlencode space="#{space}" --data-urlencode phrase="\\${varText}"
    # """
    """
    echo -e "#{space} ${varText}" | nc -U /tmp/voicecode.sock
    """
  generateDragonCommandName: () ->
    _.compact([@getTriggerPhrase(), "/!Text!/"]).join(' ')
  digest: ->
    CryptoJS.MD5(@generateDragonBody()).toString()