@Commands ?= {}
Commands.mapping = {}
Commands.history = []
Commands.context = "global"
Commands.conditionalModules = {}
Commands.lastIndividualCommand = null
Commands.lastFullCommand = null
Commands.isBeginningOfCommand = null

Commands.registerConditionalModuleCommands = (moduleName, commands) ->
  Commands.conditionalModules[moduleName] ?= {}
  _.extend Commands.conditionalModules[moduleName], commands

Commands.loadConditionalModules = ->
  _.each Commands.conditionalModules, (value, key) ->
    if CommandoSettings.modules[key] is true
      _.extend Commands.mapping, value

class Commands.Base
  constructor: (@namespace, @input) ->
    @info = Commands.mapping[@namespace] 
    @kind = @info.kind
    @repeatable = @info.repeatable
    @actions = @info.actions
  transform: ->
    Transforms[@info.transform]
  generate: ->
    if @repeatable
      Scripts.generateRepeating(@generateBaseCommand(), @repeatCount())
    else
      @generateBaseCommand()
  generateBaseCommand: ->
    switch @kind
      when "text"
        if @input?.length or @info.transformWhenBlank
          transformed = @applyTransform(@input)
          prefix = @info.prefix or ""
          suffix = @info.suffix or ""
          Scripts.makeTextCommand([prefix, transformed, suffix].join(''))
        else
          if @info.fallbackService?
            Scripts.clickServiceItem(@info.fallbackService)
      when "number"
        preCommand = if @info.padLeft
          Scripts.spacePad()
        else
          ""
        [preCommand, Scripts.makeTextCommand "#{@input}"].join("\n")
      when "action"
        if @info.contextualActions?
          scopeCases = []
          me = @
          _.each @info.contextualActions, (scenarioInfo, scenarioName) ->
            scopeCases.push(
              requirements: scenarioInfo.requirements
              generated: Scripts.joinActionCommands(scenarioInfo.actions, me.input)
            )
          fallback = if @actions
            Scripts.joinActionCommands(@actions, @input)
          else
            Scripts.outOfContext(@namespace)
            
          Scripts.applicationScope scopeCases, fallback
        else
          if @actions?.length
            Scripts.joinActionCommands(@actions, @input)
      when "word"
        transformed = Transforms.identity([@info.word].concat(@input or []))
        Scripts.makeTextCommand(transformed)
      when "combo"
        combined = _.map(@info.combo, (subCommand) ->
          command = new Commands.Base(subCommand)
          command.generate()
        ).join('\n')
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
    @info.triggerPhrase or @namespace
  getTriggerScope: ->
    @info.triggerScope or "Global"
  isSpoken: ->
    @info.isSpoken != false
  generateFullCommand: () ->
    commandText = @generateBaseCommand()
    space = @info.namespace or @namespace
    if @info.contextSensitive
      """
      on srhandler(vars)
        set dictatedText to (varText of vars)
        set toExecute to "curl http://commando:5000/parse --data-urlencode space=\\\"#{space}\\\"" & " --data-urlencode phrase=\\\"" & dictatedText & "\\\""
        do shell script toExecute
      end srhandler
      """
    else
      """
      on srhandler(vars)
        set dictatedText to (varText of vars)
        if dictatedText = "" then
        #{commandText}
        set toExecute to "curl http://commando:5000/miss --data-urlencode space=\\\"#{space}\\\""
        do shell script toExecute
        else
        set toExecute to "curl http://commando:5000/parse --data-urlencode space=\\\"#{space}\\\"" & " --data-urlencode phrase=\\\"" & dictatedText & "\\\""
        do shell script toExecute
        end if
      end srhandler
      """
  generateFullCommandWithDigest: ->
    script = @generateFullCommand()
    digest = @digest()
    """
    -- #{digest}
    #{script}
    """
  generateFullShellCommand: () ->
    space = @info.namespace or @namespace
    if @info.contextSensitive
      """
      curl http://commando:5000/parse/command --data-urlencode spoken="${varText}" --data-urlencode space="#{space}"
      """
    else
      """
      if [ -z $varText ]
      then
        osascript ~/voicecode/applescripts/#{space}.scpt
        curl http://commando:5000/parse/miss space="#{space}"
      else
        curl http://commando:5000/parse/command --data-urlencode spoken="${varText}" --data-urlencode space="#{space}"
      fi
      """
  generateDragonCommandName: () ->
    "#{@getTriggerPhrase()} /!Text!/"
  digest: ->
    CryptoJS.MD5(@generateFullCommand()).toString()