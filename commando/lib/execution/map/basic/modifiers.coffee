@commandLetters = 
  A: "arch"
  B: "brov"
  C: "char"
  D: "dell"
  E: "etch"
  F: "fomp"
  G: "goof"
  H: "hark"
  I: "ice"
  J: "jinks"
  K: "koop"
  L: "lug"
  M: "mowsh"
  N: "nerb"
  O: "ork"
  P: "pooch"
  Q: "quash"
  R: "rosh"
  S: "souk"
  T: "teek"
  U: "unks"
  V: "verge"
  W: "womp"
  X: "trex"
  Y: "yang"
  Z: "zooch"
  "1": "won"
  "2": "too"
  "3": "three"
  "4": "four"
  "5": "five"
  "6": "six"
  "7": "seven"
  "8": "ate"
  "9": "nine"
  "0": "zer"
  Return: "turn"
  "/": "slush"
  ".": "peer"
  ",": "com"
  ";": "sink"
  Delete: "leet"
  ForwardDelete: "kit"
  " ": "oosh"
  Escape: "cape"
  Tab: "raff"
  "=": "queff"
  "-": "min"
  Up: "up"
  Down: "own"
  Left: "left"
  Right: "right"
  "]": "race"
  "[": "lets"
  "\\": "pike"

@commandModifiers =
  chomm: ["command"]
  shoff: ["command", "shift"]
  shay: ["command", "option"]
  flock: ["command", "option", "shift"]
  crop: ["option"]
  snoop: ["option", "shift"]
  troll: ["control"]
  mack: ["command", "control"]
  triff: ["control", "shift"]
  prick: ["command", "control", "shift"]
  sky: ["shift"]

recommended =
  chomm: [
    "won"
    "too"
    "three"
    "four"
    "five"
    "six"
    "seven"
    "ate"
    "nine"
    "zer"
    "arch"
    "brov"
    "dell"
    "etch"
    "lug"
    "mowsh"
    "nerb"
    "pooch"
    "quash"
    "rosh"
    "slush"
    "turn"
    "leet"
  ]
  shoff: [
    "dell"
    "souk"
  ]
  troll: [
    "char"
    "zooch"
  ]
  sky: [
    "arch"
    "brov"
    "char"
    "dell"
    "etch"
    "fomp"
    "goof"
    "hark"
    "ice"
    "jinks"
    "koop"
    "lug"
    "mowsh"
    "nerb"
    "ork"
    "pooch"
    "quash"
    "rosh"
    "souk"
    "teek"
    "unks"
    "verge"
    "womp"
    "trex"
    "yang"
    "zooch"
  ]

_.each commandModifiers, (mods, prefix) ->
  _.each commandLetters, (value, key) ->
    tags = ["modifiers"]
    if recommended[prefix]?[value]?
      tags = ["modifiers", "recommended"]
    Commands.create "#{prefix}#{value}",
      description: "#{mods.join(' + ')} + #{key}"
      tags: tags
      action: ->
        @key key, mods
