# this class simply encapsulates the concept of
# commands or command extensions only applying in certain
# scenarios such as when a certain application is
# active, or an arbitrary function evaluates to true

class Scope
  @instances = {}

  # applications: list of applications where this scope is active
  # conditions: a list of functions which must all return true
  # for this scope to be active

  # application: shorthand for applications: ['single']
  # condition: shorthand for conditions: [->]
  constructor: ({@name, applications, condition, application, conditions}) ->
    @_applications = if applications
      if _.isFunction applications
        [applications]
      else
        applications
    else if application
      [application]

    @_conditions = if conditions
      conditions
    else if condition
      [condition]

  @register: (options) ->
    if @instances[options.name]?
      warning 'scopeCollision', options,
      "scope: [#{options.name}] overridden by new values"
    @instances[options.name] = new Scope(options)

  @get: (name) ->
    @instances[name]

  @resetAll: ->
    @instances = {}

  # class method Scope.active('atom')
  @active: (options) ->
    return true unless options
    # you could pass a scope name
    if typeof options is 'string'
      @get(options)?.active()
    # you could pass an object with a scope name parameter
    else if options.scope?
      @get(options.scope)?.active(options)
    else
      true

  active: (options={}) ->
    return true if @name is 'global'
    {input, context} = options
    @checkApplications() and @checkConditions({input, context})

  # allow lazy resolving of an application list
  applications: ->
    return [] unless @_applications
    _.compact _.uniq _.flattenDeep _.map @_applications, (a) ->
      if _.isFunction a
        a.call(Actions)
      else
        a

  conditions: ->
    @_conditions or []

  checkApplications: ->
    # switch global.platform
    # when 'darwin'
    # windows, linux
    return true if _.isEmpty @applications()
    Actions.currentApplication().bundleId in @applications()

  checkConditions: ({input, context}) ->
    _.every @conditions(), (condition) ->
      condition.call(Actions, input, context)

# this is just for easy access to a global version
Scope.global = Scope.register
  name: 'global'

# abstract scope is used for commands that are shared across
# multiple other scopes, but should not be global
# for example maybe 'selcrew'
Scope.abstract = Scope.register
  name: 'abstract'


module.exports = Scope