class ParserController
  instance = null
  constructor: ->
    return instance if instance?
    instance = @
    @cryptojs = require 'crypto-js'
    @fingerprintHash = null
    @fingerprint = null
    @debouncedGenerateParser = null
    @initialize()

  initialize: ->
    Events.once 'startupFlowComplete', =>
      @ready = true
      @generateParser()
      
    Events.on 'generateParserFailed', _.bind @regress, @
    Events.on 'commandEditsPerformed', =>
      @generateParser()

  generateParser: ->
    @debouncedGenerateParser ?= _.debounce @_generateParser.bind(@), 3000
    @debouncedGenerateParser()

  _generateParser: ->
    return unless @ready
    @generateFingerprint()
    @generateFingerprintHash()
    {
      fingerprintHash: oldFingerprintHash
      content: oldParser
    } = @loadFromDisk()
    if oldFingerprintHash is @fingerprintHash
      @setParser oldParser, false
    else
      try
        @getNewParser()
      catch e
        @regress e
    @debouncedGenerateParser = null

  regress: (reason) ->
    {content: oldParser} = @loadFromDisk()
    log 'parserRegression', null, "Regressing to old parser because: #{reason}"
    @setParser oldParser, false

  setParser: (parserAsAString, parserChanged = true) ->
    try
      @parser = eval parserAsAString
      log 'generateParserSuccess', true, 'Parser acquired.'
      if parserChanged
        emit 'parserChanged'
    catch e
      error 'generateParserFailed', e, 'Failed evaluating new parser.'

  parse: (phrase) ->
    result = []
    phrase = phrase + " "
    phrase = phrase.replace /\s+/g, ' '
    parts = phrase.toLowerCase().split('')
    for c, index in parts
      item = c
      # capitalize I's
      if c is "i" and (index is 0 or parts[index - 1] is " ") and (index is (parts.length - 1) or parts[index + 1] is " ")
        item = "I"
      else if c is "…"
        item = "ellipsis"
      else if c is "ï"
        item = "i"
      else if c is "–"
        item = "dash"
      else if c is ","
        item = "comma"
      result.push item
    @parser.parse result.join('')

  writeToDisk: (data) ->
    @settingsManager ?= new SettingsManager("generated/parser")
    @settingsManager.update data

  loadFromDisk: ->
    @settingsManager ?= new SettingsManager("generated/parser")
    @settingsManager.settings

  generateFingerprint: ->
    @fingerprint =
      license: Settings.license
      email: Settings.email
      grammar: Grammar.build()

  generateFingerprintHash: (fingerprint = @fingerprint)->
    @fingerprintHash = @cryptojs.MD5(JSON.stringify(fingerprint)).toString()

  isInitialized: ->
    typeof @parser isnt 'undefined'

  getNewParser: ->
    @fingerprint ?= @generateFingerprint()
    https = require 'https'
    querystring = require 'querystring'
    payload = querystring.stringify @fingerprint
    options =
      hostname: 'grammar.voicecode.io'
      port: 443
      path: '/grammar/generate'
      method: 'POST'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': Buffer.byteLength(payload)
    req = https.request options, (res) =>
      res.setEncoding 'utf8'
      data = ''
      res.on 'data', (chunk) ->
        data += chunk
      res.on 'end', =>
        data = data.replace(/[ ]+/g, " ")
        try
          newParser = eval data
        catch e
          error 'generateParserFailed', data?.substring(0, 300), 'Failed evaluating new parser.'
          return
        if newParser.success is false
          error 'generateParserFailed', data?.substring(0, 300), "Parser got no success. #{newParser.message}"
          return
        @setParser newParser
        @writeToDisk
          content: data
          fingerprint: @fingerprint
          fingerprintHash: @fingerprintHash
          updatedAt: new Date()

    req.on 'error', (e) ->
      error 'generateParserFailed', e, 'Failed requesting parser: ' + e.message

    req.write payload
    req.end()

module.exports = new ParserController
