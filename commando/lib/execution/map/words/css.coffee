singleWords = [
  "text"
  "height"
  "width"
  "bottom"
  "top"
  "left"
  "right"
  "font"
  "padding"
  "margin"
]

_.each singleWords, (word) ->
  Commands.mapping["word-#{word}"] = 
    kind: "word"
    grammarType: "textCapture"
    description: "insert the word '#{word}'"
    tags: ["user", "word"]
    triggerPhrase: word
    word: word