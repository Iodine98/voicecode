fs = require 'fs'
sqlite3 = require("sqlite3").verbose()
sync = require('synchronize')
os = require 'os'

class DragonSynchronizer
  constructor: ->
    @bundles = {global: "global"}
    @lastId = (new Date()).getTime()
    @applicationVersions = {}
    @connectMain()
    @connectDynamic()
    @commands = {}
    @lists = {}
    @insertedLists = []
    @error = false
  connectMain: ->
    file = @databaseFile("ddictatecommands")
    exists = fs.existsSync(file)
    if exists
      @database = new sqlite3.Database file, sqlite3.OPEN_READWRITE, (err) =>
        if err?
          error 'dragonSynchronizerError'
          , err, "Could not connect to Dragon Dictate command database"
          @error = true
      sync @database, 'all'
      sync @database, 'get'
      sync @database, 'run'
    else
      error 'dragonSynchronizerError', file,
      "Dragon Dictate commands database was not found at: #{file}"
      @error = true

  connectDynamic: ->
    file = @databaseFile("ddictatedynamic")
    exists = fs.existsSync(file)
    if exists
      @dynamicDatabase = new sqlite3.Database file
      , sqlite3.OPEN_READWRITE, (err) =>
        if err?
          error 'dragonSynchronizerError'
          , err, "Could not connect to Dragon Dictate dynamic database"
          @error = true
      sync @dynamicDatabase, 'all'
      sync @dynamicDatabase, 'get'
      sync @dynamicDatabase, 'run'
    else
      error 'dragonSynchronizerError', file,
      "Dragon Dictate dynamic commands database was not found at: #{file}"
      @error = true

  whoami: ->
    Execute("whoami")?.trim()

  getApplicationVersion: (bundleId) ->
    return 0 if bundleId is null # handling global
    if @applicationVersions[bundleId]?
      @applicationVersions[bundleId]
    else
      existing = @database.get "SELECT * FROM ZCOMMAND WHERE ZAPPBUNDLE = '#{bundleId}' LIMIT 1"
      found = if existing?.ZAPPVERSION?
        existing.ZAPPVERSION
      else
        SystemInfo.applicationMajorVersionFromBundle bundleId
      @applicationVersions[bundleId] = found
      found

  getUsername: ->
    if @username?
      @username
    else
      @username = @whoami()
      @username

  normalizeBundleId: (bundleId) ->
    if bundleId is "global"
      null
    else
      bundleId

  digest: (triggerPhrase, bundleId) ->
    CryptoJS.MD5([triggerPhrase, bundleId].join('')).toString()

  getJoinedCommands: ->
    @all """SELECT * FROM ZCOMMAND AS C
    LEFT OUTER JOIN ZACTION AS A ON A.Z_PK=C.Z_PK
    LEFT OUTER JOIN ZTRIGGER AS T ON T.Z_PK=C.Z_PK
    """
  createListItem: (name, listId) ->
    name = name.split(' ').join('-')
    @dynamicDatabase.run "INSERT INTO ZSPECIFICTERM (Z_ENT, Z_OPT, ZNUMERICVALUE, ZGENERALTERM, ZNAME) VALUES (2, 1, 0, $listId, $name)",
      $name: name
      $listId: listId

  getNextRecordId: ->
    result = @database.get "SELECT * FROM ZTRIGGER ORDER BY Z_PK DESC LIMIT 1"
    (result?.Z_PK or 0) + 1
    # @get "SELECT last_insert_rowid() FROM ZTRIGGER"

  createCommandId: ->
    id = Date.now()
    # in case of collision
    if id is @lastId
      id = @lastId + 1
    @lastId = id
    id

  createCommand: ({bundleId, triggerPhrase, body}) ->
    locale = Settings.dragon_darwin.localeSettings[Settings.core.locale]
    commandId = @createCommandId()
    bundleId = null if bundleId is 'global'
    applicationVersion = @getApplicationVersion bundleId

    id = @getNextRecordId()
    username = @getUsername()
    @database.run "BEGIN TRANSACTION;"
    @database.run "INSERT INTO ZTRIGGER (Z_ENT, Z_OPT, ZISUSER, ZCOMMAND, ZCURRENTCOMMAND, ZDESC, ZSPOKENLANGUAGE, ZSTRING) VALUES (4, 1, 1, #{id}, #{id}, 'voicecode', '#{locale.dragonTriggerSpokenLanguage}', $triggerPhrase);", {$triggerPhrase: triggerPhrase}
    @database.run "INSERT INTO ZACTION (Z_ENT, Z_OPT, ZISUSER, ZCOMMAND, ZCURRENTCOMMAND, ZOSLANGUAGE, ZTEXT) VALUES (1, 1, 1, #{id}, #{id}, '#{locale.dragonOsLanguage}', $body);", {$body: body}
    @database.run "INSERT INTO ZCOMMAND (Z_ENT, Z_OPT, ZACTIVE, ZAPPVERSION, ZCOMMANDID, ZDISPLAY, ZENGINEID, ZISCOMMAND,
    ZISCORRECTION, ZISDICTATION, ZISSLEEP, ZISSPELLING, ZVERSION, ZCURRENTACTION, ZCURRENTTRIGGER, ZLOCATION,
    ZAPPBUNDLE, ZOSLANGUAGE, ZSPOKENLANGUAGE, ZTYPE, ZVENDOR) VALUES (2, 4, 1, #{applicationVersion}, #{commandId},
    1, -1, 1, 0, 0, 0, 1, 1, #{id}, #{id}, NULL, $bundleId, '#{locale.dragonOsLanguage}', '#{locale.dragonCommandSpokenLanguage}', 'ShellScript', $username);", {$bundleId: @normalizeBundleId(bundleId), $username: username}
    @database.run "UPDATE Z_PRIMARYKEY SET Z_MAX = #{id} WHERE Z_NAME = 'action'"
    @database.run "UPDATE Z_PRIMARYKEY SET Z_MAX = #{id} WHERE Z_NAME = 'trigger'"
    @database.run "UPDATE Z_PRIMARYKEY SET Z_MAX = #{id} WHERE Z_NAME = 'command'"
    @database.run "COMMIT TRANSACTION;"

  deleteCommand: (id) ->
    if id
      @database.run "BEGIN TRANSACTION;"
      @database.run "DELETE FROM ZCOMMAND WHERE Z_PK = #{id};"
      @database.run "DELETE FROM ZACTION WHERE Z_PK = #{id};"
      @database.run "DELETE FROM ZTRIGGER WHERE Z_PK = #{id};"
      @database.run "COMMIT TRANSACTION;"

  databaseFile: (extension) ->
    home = os.homedir()
    file = [home, "Library/Application\ Support/Dragon/Commands/#{@getUsername()}.#{extension}"].join("/")
    if developmentMode
      file = [home, "Documents/Dragon/Commands/#{@getUsername()}.#{extension}"].join("/")
    file

  deleteAllDynamic: ->
    @dynamicDatabase.run "DELETE FROM ZGENERALTERM"
    @dynamicDatabase.run "DELETE FROM ZSPECIFICTERM"

  deleteAllStatic: ->
    @database.run "DELETE FROM ZACTION"
    @database.run "DELETE FROM ZCOMMAND"
    @database.run "DELETE FROM ZTRIGGER"

  synchronize: ->
    emit 'dragonSynchronizingStarted'
    if @error
      error 'dragonSynchronizerError'
      , null, "Could not synchronize with Dragon Dictate database"
    else
      @deleteAllStatic()
      @deleteAllDynamic()
      @synchronizeStatic()
      @synchronizeDynamic()
      unless Settings.dragon_darwin.keepDefaultDragonCommands
        @removeDefaultDragonCommands()
    unless @error
      emit 'dragonSynchronizingEnded'
    @database?.close()

  createList: (name, items, bundleId = '#') ->
    if @error
      error 'dragonSynchronizeDynamicError'
      , null, "Dragon database not connected"

    @dynamicDatabase.run "INSERT INTO ZGENERALTERM (Z_ENT, Z_OPT, ZBUNDLEIDENTIFIER, ZNAME, ZSPOKENLANGUAGE, ZTERMTYPE) VALUES (1, 1, $bundleId, $name, $spokenLanguage, 'Alt')",
      $name: name
      $spokenLanguage: Settings.dragon_darwin.localeSettings[Settings.core.locale].dragonTriggerSpokenLanguage
      $bundleId: bundleId
    # get the new id
    result = @dynamicDatabase.get "SELECT * FROM ZGENERALTERM WHERE ZNAME = '#{name}' LIMIT 1"
    id = result?.Z_PK

    for item in items
      @createListItem item, id

  synchronizeStatic: () ->
    if @error
      error 'dragonSynchronizeStaticError'
      , null, "Dragon database not connected"
      return false
    needsCreating = []

    chainedYesNo = [yes, no]
    DragonCommand = require './dragon_command'
    debug "enabled commands count", Commands.getEnabled().length
    for id in Commands.getEnabled()
      command = new DragonCommand(id, null)
      continue unless command.needsDragonCommand()
      @commands[id] = command
      if command.rule?
        @lists[id] = command.dragonLists()
      if Settings.dragon_darwin.dragonCommandMode is 'pure-vocab'
        continue if id isnt 'dragon_darwin:catch-all'
      for hasChain in chainedYesNo
        # special case
        continue if id is 'dragon_darwin:catch-all' and hasChain is no
        # continue if _.isEmpty command.implementations
        dragonName = command.generateCommandName hasChain
        dragonBody = command.generateCommandBody hasChain
        bundleIds = command.applications()
        # if a command has none, or more than 1 implementation,
        # consider it global
        if command.isGlobal() or _.isEmpty(bundleIds)
          bundleIds = ['global']
        for bundleId in bundleIds
          continue unless Actions.checkBundleExistence(bundleId)
          continue unless dragonName?
          needsCreating.push
            bundleId: bundleId
            triggerPhrase: dragonName.trim()
            body: dragonBody.trim()

    debug "Commands to create: " + needsCreating.length
    _.each needsCreating, (item) =>
      @createCommand item

  synchronizeDynamic: ->
    if @error
      error 'dragonSynchronizeDynamicError'
      , null, "Dragon database not connected"
      return false
    for id, lists of @lists
      for listName, speakableList of lists
        command = @commands[id]
        # continue if _.isEmpty command.implementations
        bundleIds = command.applications()
        if command.isGlobal() or _.isEmpty(bundleIds)
          bundleIds = ['global']
        for bundleId in bundleIds
          continue unless Actions.checkBundleExistence(bundleId)
          bundleId = '#' if bundleId is 'global'
          uniqueName = [bundleId, listName].join('')
          unless uniqueName in @insertedLists
            @createList listName, speakableList.speakableValues(), bundleId
            @insertedLists.push uniqueName

  removeDefaultDragonCommands: ->
    files = [
      'Global-eng'
      'GlobalSearch-eng'
      'GlobalSocial-eng'
      'iCal-eng'
      'iChat-eng'
      'Mail-eng'
      'Safari-eng'
      'TextEdit-eng'
      'Word-eng'
      'Finder-eng'
    ]
    _.each files, @clearDragonCommandFile.bind(@)
  clearDragonCommandFile: (name) ->
    home = os.homedir()
    file = [home, "Library/Application\ Support/Dragon/Commands/#{name}.ddictatecommands"].join("/")
    if fs.existsSync(file)
      db = new sqlite3.Database file, sqlite3.OPEN_READWRITE
      sync db, 'run'      
      db.run "DELETE FROM ZACTION"
      db.run "DELETE FROM ZCOMMAND"
      db.run "DELETE FROM ZTRIGGER"    
      db.close()
    else
      warning 'clearDragonCommandFile', file, "couldn't find dragon command file"

module.exports = new DragonSynchronizer
