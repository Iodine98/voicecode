Commands.createDisabled
  "shell-cd":
    description: "change directory"
    tags: ["domain-specific", "shell"]
    triggerScopes: ["iTerm", "Terminal"]
    triggerPhrase: "cd"
    action: ->
      @string "cd ; ls"
      _(4).times =>
        @key "Left"
  "shell-engage":
    description: "hover your mouse over a directory name output from a 'ls' command in the terminal, and this command will 'cd' to that directory"
    tags: ["domain-specific", "shell"]
    triggerScope: "iTerm"
    triggerPhrase: "engage"
    action: ->
      @rightClick()
      @delay 50
      @string "cd "
      @key "V", 'command'
      @string "; ls"
      @key "Return"
  "shell-list":
    grammarType: "textCapture"
    description: "list directory contents (takes dynamic arguments)"
    tags: ["domain-specific", "shell"]
    triggerScopes: ["iTerm", "Terminal"]
    triggerPhrase: "shell list"
    action: (input) ->
      options = _.map((input or []), (item) ->
        " -#{item}"
      ).join(" ")
      @string "ls #{options}"
      @key "Return"
      
  "shell-history":
    grammarType: "numberCapture"
    description: "display the last [n](default all) shell commands executed"
    tags: ["domain-specific", "shell"]
    triggerPhrase: "shell history"
    triggerScopes: ["iTerm", "Terminal"]
    action: (input) ->
      @string "history #{input or ""}"
      @key "Return"
  "shell-recall":
    description: "hovering the mouse over the left-hand number of a result from the history output, this will re-execute the command"
    tags: ["domain-specific", "shell"]
    triggerPhrase: "shell recall"
    triggerScope: "iTerm"
    action: ->
      @rightClick()
      @delay 50
      @key "!"
      @key "V", 'command'
      @key "Return"
  "shell-edit":
    description: "open file in editor"
    tags: ["domain-specific", "shell"]
    triggerPhrase: "shell edit"
    triggerScope: "iTerm"
    action: ->
      @rightClick()
      @delay 50
      @key "$EDITOR "
      @key "V", 'command'
      @key "Return"
  "durrup":
    description: "navigate to the parent directory"
    tags: ["domain-specific", "shell"]
    triggerScopes: ["iTerm", "Terminal"]
    action: ->
      @string "cd ..; ls"
      @key "Return"
  "shell-direct":
    grammarType: "textCapture"
    description: "changes directory to any directory in the predefined list"
    tags: ["text", "domain-specific", "shell"]
    triggerPhrase: "direct"
    action: (input) ->
      if input?.length
        current = @currentApplication()
        directory = Scripts.fuzzyMatch Settings.directories, input.join(' ')
        if current is "iTerm" or current is "Terminal"
          @string "cd #{directory} ; ls \n"
        else
          @openApplication("iTerm")
          @key "T", 'command'
          @delay 200
          @string "cd #{directory} ; ls"
          @key "Return"
  "shell":
    grammarType: "textCapture"
    description: "insert a shell command from the predefined shell commands list"
    tags: ["text", "shell"]
    aliases: ["shall", "chell"]
    action: (input) ->
      if input?.length
        text = Scripts.fuzzyMatch Settings.shellCommands, input.join(' ')
        @string text
