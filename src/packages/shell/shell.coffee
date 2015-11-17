Context.register
  name: 'shell'
  applications: Settings.terminalApplications

pack = Packages.register
  name: 'shell'
  description: 'General commands for shell / console usage'
  context: 'shell'

pack.after
  'git:status': ->
    @enter()

pack.commands
  'change-directory':
    spoken: 'cd'
    description: 'change directory'
    tags: ['domain-specific', 'shell']
    continuous: false
    action: ->
      @string 'cd ; ls'
      @left 4

  'list-directories':
    spoken: 'shell list'
    grammarType: 'textCapture'
    description: 'list directory contents (takes dynamic arguments)'
    tags: ['domain-specific', 'shell']
    continuous: false
    inputRequired: false
    action: (input) ->
      options = _.map((input or []), (item) ->
        " -#{item}"
      ).join(" ")
      @string "ls #{options}"
      @enter()

  'display-history':
    spoken: 'shell history'
    grammarType: 'numberCapture'
    description: 'display the last [n](default all) shell commands executed'
    tags: ['domain-specific', 'shell']
    continuous: false
    inputRequired: false
    action: (input) ->
      @string "history #{input or ''}"
      @enter()
  'parent-directory':
    spoken: 'durrup'
    description: 'navigate to the parent directory'
    tags: ['domain-specific', 'shell']
    action: ->
      @string 'cd ..; ls'
      @enter()

# global
pack.commands
  context: 'global'
,
  'open-directory':
    spoken: 'direct'
    grammarType: 'textCapture'
    description: 'changes directory to any directory in the predefined list'
    tags: ['text', 'domain-specific', 'shell']
    continuous: false
    inputRequired: true
    action: (input) ->
      if input?.length
        current = @currentApplication()
        directory = @fuzzyMatch Settings.directories, input.join(' ')
        if @inTerminal()
          @string "cd #{directory} ; ls \n"
        else
          @openDefaultTerminal()
          @newTab()
          @delay 200
          @string "cd #{directory} ; ls"
          @enter()
  'insert-common-command':
    spoken: 'shell'
    grammarType: 'custom'
    rule: '<spoken> (shellcommands)'
    description: 'insert a shell command from the predefined shell commands list'
    tags: ['text', 'shell']
    misspellings: ['shall', 'chell']
    variables:
      shellcommands: -> _.keys Settings.shellCommands
    continuous: false
    inputRequired: true
    action: ({shellcommands}) ->
      text = @fuzzyMatch Settings.shellCommands, shellcommands
      @string text