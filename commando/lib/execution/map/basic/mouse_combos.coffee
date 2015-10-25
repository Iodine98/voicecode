Commands.createDisabled
  'chibble':
    description: 'selects the entire line of text cursor hovers over'
    tags: ['mouse', 'combo', 'recommended']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @key 'Left', 'command'
      @key 'Right', 'command shift'
  'dookoosh':
    grammarType: 'oneArgument'
    description: 'mouse double click, then copy'
    tags: ['mouse', 'combo', 'recommended', 'clipboard']
    mouseLatency: true
    inputRequired: false
    action: (input, context) ->
      @do 'duke', input, context
      @do 'stoosh', input
  'doopark':
    grammarType: 'oneArgument'
    description: 'mouse double click, then paste'
    tags: ['mouse', 'combo', 'clipboard']
    inputRequired: false
    mouseLatency: true
    action: (input, context) ->
      @do 'duke', input, context
      @do 'spark', input
  'chiffpark':
    grammarType: 'oneArgument'
    description: 'mouse single click, then paste'
    tags: ['mouse', 'combo', 'recommended', 'clipboard']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'spark', input
  'shackloosh':
    grammarType: 'oneArgument'
    description: 'select entire line, then copy'
    tags: ['selection', 'combo', 'clipboard']
    inputRequired: false
    action: (input) ->
      @do 'shackle'
      @do 'stoosh', input
  'shacklark':
    grammarType: 'oneArgument'
    description: 'select entire line, then paste'
    tags: ['selection', 'combo', 'clipboard']
    inputRequired: false
    action: (input) ->
      @do 'shackle'
      @do 'spark', input
  'chibloosh':
    grammarType: 'oneArgument'
    description: 'select entire line, then copy'
    tags: ['selection', 'combo', 'clipboard']
    mouseLatency: true
    inputRequired: false
    action: (input, context) ->
      @do 'chibble', input, context
      @do 'stoosh', input
  'chiblark':
    grammarType: 'oneArgument'
    description: 'select entire line, then paste'
    tags: ['selection', 'combo', 'clipboard']
    mouseLatency: true
    inputRequired: false
    action: (input, context) ->
      @do 'chibble', input, context
      @do 'spark', input
  'chiffacoon':
    description: 'click, then insert new line below'
    tags: ['mouse', 'combo']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'shockoon'
  'chiffkoosh':
    description: 'click, then insert a space'
    tags: ['mouse', 'combo', 'space']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'skoosh'
  'sappy':
    misspellings: ['sapi']
    description: 'click, then delete entire line'
    tags: ['mouse', 'combo']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'snipline'
  'sapper':
    description: 'click, then delete line to the right'
    tags: ['mouse', 'combo']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'snipper'
  'sapple':
    description: 'click, then delete line to the left'
    tags: ['mouse', 'combo']
    mouseLatency: true
    action: (input, context) ->
      @do 'chiff', input, context
      @do 'snipple'
  'grabsy':
    description: 'will grab the text underneath the mouse, then insert it at the current cursor location. Only supports a few applications for now but will be expanded.'
    tags: ['mouse', 'combo', 'clipboard']
    action: () ->
      switch @currentApplication()
        when "iTerm"
          @rightClick()
          @rightClick()
          @paste()
        when "Sublime Text"
          @doubleClick()
          @delay 200
          @copy()
          @delay 50
          @sublime()
            .jumpBack()
            .jumpBack()
            .execute()
          @paste()
