Commands.create
  "switchy":
    kind: "action"
    grammarType: "individual"
    description: "move current line up"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      @key "Up", ['control', 'command']

  "switcho":
    kind: "action"
    grammarType: "individual"
    description: "move current line down"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      @key "Down", ['control', 'command']

  "bracken":
    kind: "action"
    grammarType: "individual"
    description: "expand selection to brackets"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      @key "S", ['control', 'command', 'option']


  "spring":
    kind: "action"
    grammarType: "numberCapture"
    description: "go to line number. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input
        @exec "subl --command 'goto_line {\"line\": #{input}}'"
      else
        @key "G", ['control']

  "sprinkler":
    kind: "action"
    grammarType: "numberCapture"
    description: "go to line number then position cursor at end of line. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input
        @exec """subl --command 'goto_line {"line": #{input}}' """
        @key "Right", ['command']
      else
        @key "G", ['control']

  "sprinkoon":
    kind: "action"
    grammarType: "numberCapture"
    description: "go to line number then insert a new line below. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input
        @exec """subl --command 'goto_line {"line": #{input}}' """
        @key "Return", ['command']
      else
        @key "G", ['control']

  "spackle":
    kind: "action"
    grammarType: "numberCapture"
    description: "go to line number then select entire line. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input
        @exec """
        subl --command 'goto_line {"line": #{input}}' \
        --command 'expand_selection {"to": "line"}'
        """
      else
        @key "G", ['control']

  "selrang":
    kind: "action"
    grammarType: "numberCapture"
    description: "selects text in a line range: selrang ten twenty. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input
        number = input.toString()
        length = Math.floor(input.length / 2)
        first = number.substr(0, length)
        last = number.substr(length, length + 1)
        first = parseInt(first)
        last = parseInt(last)
        if last < first
          temp = last
          last = first
          first = temp
        last += 1
        script = """
        subl --command 'goto_line {"line": #{first}}' \
        --command 'set_mark' \
        --command 'goto_line {"line": #{last}}' \
        --command 'select_to_mark' \
        --command 'clear_bookmarks {"name": "mark"}'
        """
        @exec script
  
  "seltil":
    kind: "action"
    grammarType: "numberCapture"
    description: "selects text from current position through ('til) spoken line number: seltil five five. Requires subl - https://github.com/VoiceCode/docs/wiki/Sublime-Text-Setup"
    tags: ["domain-specific", "sublime"]
    triggerScope: "Sublime Text"
    action: (input) ->
      if input?
        script = """
        subl --command 'set_mark' \
        --command 'goto_line {"line": #{input}}' \
        --command 'select_to_mark' \
        --command 'clear_bookmarks {"name": "mark"}'
        """
        @exec script
