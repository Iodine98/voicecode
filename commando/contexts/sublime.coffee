class Contexts.Sublime extends Contexts.Base
  
  @applicationName: "Sublime Text"

  @addCommands: (commands) ->
    _.each commands, (value, key) ->
      Contexts.Sublime::[key] = (options) ->
        @do value, options    

  @commands:
    setMark: 'set_mark'
    selectToMark: 'select_to_mark'
    clearBookmarks: 'clear_bookmarks'
    selectNextWord: 'select_next_word'
    selectPreviousWord: 'select_previous_word'
    moveTo: 'move_to'

  constructor: (command, options) ->
    @commands = []
    if command?
      @do command, options
    this
  do: (command, options) ->
    item = {command: command}
    item.options = options if options?
    @commands.push item
    # return this so that commands can be chained
    this
  action: ->
    Actions.exec @buildCommand()
  buildCommand: ->
    results = ["subl"]
    for command in @commands
      options = if command.options?
        JSON.stringify command.options
      else
        ''
      results.push "--command '#{[command.command, options].join(' ')}'"
    results.join ' '
  documentation: ->
    buildCommand()
  goToLine: (line) ->
    @do "goto_line", {line: line}
    this
  clearMark: ->
    @do "clear_bookmarks", {name: "mark"}
    this
  selectRange: (first, last) ->
    f = first
    l = last
    if last < first
      f = last
      l = first
    @goToLine(f)
      .setMark()
      .goToLine(l + 1)
      # .moveTo(to: "eol", extend: false)
      .selectToMark()
      .clearMark()

Contexts.Sublime.addCommands(Contexts.Sublime.commands)