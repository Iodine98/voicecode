class Command
  constructor: (name, @input = null, @context = {}) ->
    _.extend @, Commands.get name
    @normalizeInput()

  normalizeInput: ->
    if @rule?
      @input = @grammar.normalizeInput(@input)
    else
      switch @grammarType
        when "textCapture"
          @input = Actions.normalizeTextArray @input
        when "numberRange"
          @input = @normalizeNumberRange(@input)

  transform: ->
    Transforms[@transform]

  package: ->
    if @packageId?
      Packages.get @packageId

  generate: ->
    input = @input
    context = @generateContext()
    currentApplication = Actions.currentApplication()
    funk = if @action?
      action = @action
      -> action.call(@, input, context)
    else
      -> null

    core = unless _.isEmpty @before
      extensions = []
      extensions.push funk
      _.each @before, ({action: e, info}) ->
        if Scope.active(info)
          extensions.push ->
            e.call(@, input, context)
      ->
        @extensionsContinue = true
        for callback in extensions.reverse()
          if @extensionsContinue
            callback.call(@, input, context)
    else
      funk
    segments = []

    # core actions
    segments.push core

    # after actions
    if @after?
      afterList = []
      _.each @after, ({action: e, info}) ->
        if Scope.active(info)
          afterList.push ->
            e.call(@, input, context)
      segments.push ->
        for callback in afterList.reverse()
          callback.call(@)

    # needs to return an executable function that can be called later.
    # context should be explicitly set to an 'Actions' instance when called
    ->
      for segment in segments
        segment?.call(@)

  getApplications: ->
    unless _.isEmpty @applications
      @applications
    else if @scope is "abstract"
      results = Scope.applications(@scope)
      _.each @before, (value, key) ->
        results = _.union results, Scope.applications(value.info.scope)
      _.each @after, (value, key) ->
        results = _.union results, Scope.applications(value.info.scope)
      results
    else
      Scope.applications(@scope)

  generateContext: ->
    @context

  normalizeNumberRange: (input) ->
    if typeof input is "object"
      input
    else
      if input?
        {first: parseInt(input)}
      else
        {first: null, last: null}

  getTriggerPhrase: ->
    if @triggerPhrase?
      @triggerPhrase
    else
      @spoken

module.exports = Command
