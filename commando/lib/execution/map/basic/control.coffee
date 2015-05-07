Commands.createDisabled
  "shin":
    description: "does nothing, but enters into voice code"
    aliases: ["chin"]
    tags: ["text", "recommended"]
    action: -> 
      null
  "skoosh":
    description: "insert a space"
    tags: ["space", "recommended"]
    action: ->
      @key " "
  "skoopark":
    description: "insert a space then paste the clipboard"
    tags: ["space", "combo", "copy-paste"]
    action: ->
      @key " "
      @key "V", "command"
  "shockoon":
    description: "Inserts a new line below the current line"
    tags: ["return", "combo", "recommended"]
    action: ->
      if @currentApplication() is "sublime"
        @key "Return", "command"
      else
        @key "Right", "command"
        @key "Return"
  "shocktar":
    description: "Inserts a new line then a tab"
    tags: ["return", "tab", "combo"]
    action: ->
      @key "Return"
      @key "Tab"
  "shockey":
    description: "Inserts a new line above the current line"
    aliases: ["chalky", "shocking", "shocky"]
    tags: ["return", "combo", "recommended"]
    action: ->
      if @currentApplication() is "sublime"
        @key "Return", "command shift"
      else
        @key "Left", "command"
        @key "Return"
        @key "Up"