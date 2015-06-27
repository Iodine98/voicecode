Commands.createDisabled
  "duke":
    description: "double click"
    tags: ["mouse", "recommended"]
    action: ->
      @doubleClick()
  "chipper":
    description: "right click"
    tags: ["mouse", "recommended"]
    action: ->
      @rightClick()
  "chiff":
    description: "left click"
    tags: ["mouse", "recommended"]
    action: ->
      @click()
  "triplick":
    description: "left click"
    tags: ["mouse", "recommended"]
    action: ->
      @tripleClick()
  "shicks":
    description: "shift+click"
    tags: ["mouse", "recommended"]
    aliases: ["chicks"]
    action: ->
      @shiftClick()
  "chom lick":
    description: "command+click"
    tags: ["mouse"]
    vocabulary: true
    action: ->
      @commandClick()
  "crop lick":
    description: "option+click"
    tags: ["mouse"]
    vocabulary: true
    action: ->
      @optionClick()
  "pretzel":
    description: "press down mouse and hold"
    tags: ["mouse"]
    action: ->
      @mouseDown()
  "relish":
    description: "release the mouse after press and hold"
    tags: ["mouse"]
    action: ->
      @mouseUp()
