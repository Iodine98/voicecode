Commands.createDisabled
  'cursor.lineNumber':
    spoken: 'spring'
    grammarType: 'integerCapture'
    description: 'go to line number.'
    tags: ['cursor']
    inputRequired: false
    action: (input) -> null

  'combo.cursorMoveLineNumberAndWayRight':
    spoken: 'sprinkler'
    grammarType: 'integerCapture'
    description: 'go to line number then position cursor at end of line.'
    tags: ['cursor']
    inputRequired: false
    action: (input) ->
      @do 'cursor.lineNumber', input
      if input?
        @do 'select.way.right'

  'combo.cursorMoveLineNumberAndWayLeft':
    spoken: 'sprinkle'
    grammarType: 'integerCapture'
    description: 'Go to line number then position cursor at beginning of line.'
    tags: ['selection', 'IDE', 'cursor']
    inputRequired: false
    action: (input) ->
      @do 'cursor.lineNumber', input
      if input?
        @do 'cursor.way.left'

  'combo.cursorMoveLineNumberThenNewLine':
    spoken: 'sprinkoon'
    grammarType: 'integerCapture'
    description: 'Go to line number then insert a new line below.'
    tags: ['selection', 'IDE', 'cursor']
    inputRequired: false
    action: (input) ->
      @do 'cursor.lineNumber', input
      if input?
        @do 'common.newLineBelow'
  'combo.cursorMoveLineNumberThenSelectLineText':
    spoken: 'spackle'
    grammarType: 'integerCapture'
    description: 'Go to line number then select entire line.'
    tags: ['selection', 'IDE', 'cursor']
    inputRequired: false
    action: (input) ->
      @do 'cursor.lineNumber', input
      if input?
        @do 'select.line.text'

  'selection.expandToScope':
    spoken: 'bracken'
    description: 'Expand selection to quotes, parens, braces, or brackets.'
    tags: ['selection', 'IDE']
    action: (input) ->
      null

  'select.lineNumberRange':
    spoken: 'selrang'
    grammarType: 'integerCapture'
    description: 'Selects text in a line range: selrang ten twenty.'
    tags: ['selection', 'IDE']
    inputRequired: true
    action: (input) ->
      null

  'selection.extendToLineNumber':
    spoken: 'seltil'
    grammarType: 'integerCapture'
    description: 'selects text from current position through spoken line number: seltil five five.'
    tags: ['selection', 'IDE']
    inputRequired: true
    action: (input) ->
      null

  'insert.fromLineNumber':
    spoken: 'clonesert'
    grammarType: 'integerCapture'
    description: 'Insert the text from another line at the current cursor position'
    tags: ['atom']
    inputRequired: true
    action: (input) ->
      null

  'editor.toggleComment':
    spoken: 'trundle'
    grammarType: 'numberRange'
    tags: ['IDE']
    description: 'Toggle comments on the line or range'
    inputRequired: false
    action: ({first, last} = {}) ->
      null