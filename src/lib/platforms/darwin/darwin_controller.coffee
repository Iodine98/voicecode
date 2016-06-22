net = require 'net'
fs = require 'fs'
forever = require 'forever'

class DarwinController
  instance = null
  constructor: ->
    return instance if instance?
    instance = @

    @loadFrameworks()

    @historyGrowl = []
    @historyDragon = []
    @historyStatusWindow = []

    @methodCallTimes = {}
    @applicationLastChangedAt = Date.now()

    Events.once 'startupComplete', =>
      unless developmentMode
        @startEventMonitor()
      else
        @listenOnSocket "/tmp/voicecode_events_dev.sock", @systemEventHandler

      if Settings.slaveMode
        @listenAsSlave()
      else
        @listen()

  loadFrameworks: ->
    $.framework 'Foundation'
    $.framework 'Quartz'
    $.framework 'AppKit'

  startEventMonitor: ->
    @listenOnSocket "/tmp/voicecode_events.sock", @systemEventHandler

    @eventMonitor = forever.start '',
      command: "#{projectRoot}/bin/DarwinEventMonitor.app/Contents/MacOS/DarwinEventMonitor"
      silent: true
    @eventMonitor.on 'start', =>
      log 'eventMonitorStarted', @eventMonitor, "Monitoring system events"
      process.on 'exit', => @eventMonitor.stop()

    @eventMonitor.on 'exit:code', (code) ->
      error 'eventMonitorStopped', code, "Event monitor stopped with code: #{code}"

  applicationChanged: ({event, bundleId, name}) ->
    @applicationLastChangedAt = Date.now()
    Actions.setCurrentApplication {name, bundleId}

  mouseLeftClickHandler: (event) ->
    emit 'mouse.leftClick', event

  listen: ->
    global.slaveController = new SlaveController()
    slaveController.connect()

    @listenOnSocket "/tmp/voicecode.sock", @dragonHandler
    @listenOnSocket "/tmp/voicecode2.sock", @growlHandler

  listenOnSocket: (socketPath, callback) ->
    fs.stat socketPath, (error) =>
      unless error
        fs.unlinkSync socketPath
      unixServer = net.createServer (connection) =>
        connection.on 'data', callback.bind(@)
      unixServer.listen socketPath

  systemEventHandler: (buffer) ->
    event = JSON.parse buffer.toString('utf8')
    # debug 'systemEventHandler', event
    switch event.event
      when 'applicationChanged'
        @applicationChanged event
      when 'leftClick'
        @mouseLeftClickHandler event
      when 'recognizedText'
        unless developmentMode
          @statusWindowTextHandler event

  normalizePhraseComparison: (phrase) ->
    if ParserController.isInitialized()
      JSON.stringify ParserController.parse(phrase.toLowerCase() + " ")
    else
      error 'chainMissingParser', null, "The parser is not initialized -
      probably a problem with the license code, email, or internet connection"
      null
      # phrase.toLowerCase()

  findPreviousPhrase: (list, name, phrase) ->
    _.find list, (item) ->
      item.phrase is phrase and item[name] != true

  dragonHandler: (data) ->
    phrase = data.toString('utf8').replace("\n", "")
    debug 'dragonPhrase', phrase
    normalized = @normalizePhraseComparison(phrase)

    oldGrowl = @findPreviousPhrase @historyGrowl, 'dragon', normalized
    oldStatusWindow = @findPreviousPhrase @historyStatusWindow, 'dragon', normalized

    proceed = true

    if oldGrowl?
      #ignore
      oldGrowl.dragon = true
      proceed = false

    if oldStatusWindow?
      #ignore
      oldStatusWindow.dragon = true
      proceed = false

    if proceed
      @historyDragon.unshift
        phrase: normalized

      if slaveController.isActive()
        slaveController.process phrase
      else
        @executeChain(phrase)

    @historyDragon.splice(10) # don't accrue too much history

  growlHandler: (data) ->
    phrase = data.toString('utf8').replace("\n", "")
    debug 'growlPhrase', phrase
    normalized = @normalizePhraseComparison(phrase)

    oldDragon = @findPreviousPhrase @historyDragon, 'growl', normalized
    oldStatusWindow = @findPreviousPhrase @historyStatusWindow, 'growl', normalized
    proceed = true

    if oldDragon?
      #ignore
      oldDragon.growl = true
      proceed = false

    if oldStatusWindow?
      #ignore
      oldStatusWindow.growl = true
      proceed = false

    if proceed
      @historyGrowl.unshift
        phrase: normalized

      if slaveController.isActive()
        slaveController.process phrase
      else
        @executeChain(phrase)

    @historyGrowl.splice(10) # don't accrue too much history

  statusWindowTextHandler: (event) ->
    return unless event.phrase?.length
    # if we recently switched applications then sometimes the status window fires twice
    # about 2 - 4 seconds apart, so if that's the case ignore the second one
    if event.phrase is @_statusWindowPreviousPhrase
      if Date.now() - @applicationLastChangedAt < 4500
        debug 'statusWindowIgnored', event.phrase, Date.now() - @applicationLastChangedAt
        return
      else
        debug 'statusWindowNotIgnored', event.phrase, Date.now() - @applicationLastChangedAt

    @_statusWindowPreviousPhrase = event.phrase

    lastCalled = @methodCallTimes.statusWindowTextHandler
    if (not lastCalled?) or (lastCalled? and (Date.now() - lastCalled) > 800)
      @methodCallTimes.statusWindowTextHandler = Date.now()
      phrase = event.phrase
      debug 'statusWindowPhrase', phrase,
      normalized = @normalizePhraseComparison(phrase)

      oldDragon = @findPreviousPhrase @historyDragon, 'status', normalized
      oldGrowl = @findPreviousPhrase @historyGrowl, 'status', normalized

      proceed = true
      if oldDragon?
        #ignore
        oldDragon.status = true
        proceed = false

      if oldGrowl?
        #ignore
        oldGrowl.status = true
        proceed = false

      if proceed
        @historyStatusWindow.unshift
          phrase: normalized

        if slaveController.isActive()
          slaveController.process phrase
        else
          @executeChain(phrase)

      @historyStatusWindow.splice(10) # don't accrue too much history
    else
      # skip

  executeChain: (phrase) ->
    Fiber(->
      HAS_FIBER = true
      new Chain(phrase).execute()
    ).run()



module.exports = new DarwinController
