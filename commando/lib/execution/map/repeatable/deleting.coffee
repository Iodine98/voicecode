_.extend Commands.mapping,
  "kef":
    kind: "action"
    grammarType: "individual"
    description: "press option-delete"
    tags: ["deleting"]
    action: ->
      @key "Delete", ["option"]
  "steffi":
    kind: "action"
    grammarType: "individual"
    description: "delete a partial word at a time"
    tags: ["deleting"]
    action: ->
      current = @currentApplication()
      if current is "Sublime Text"
        @key "Delete", ["control"]
      else if current is "iTerm" and @context is "vim"
        @key "Delete", ["option"]
      else if current is "Emacs" or (current is "iTerm" and @context is "emacs")
        @key "Delete", ["option"]
      else
        @key "Delete", ["option"]
  "stippy":
    kind: "action"
    grammarType: "individual"
    description: "forward delete a partial word at a time"
    tags: ["deleting"]
    action: ->
      if @currentApplication() is "Sublime Text"
        @key "ForwardDelete", ["control"]
      else
        @key "ForwardDelete", ["option"]
  "kite":
    kind: "action"
    grammarType: "individual"
    description: "forward delete a word at a time"
    tags: ["deleting"]
    action: ->
      @key "ForwardDelete", ['option']