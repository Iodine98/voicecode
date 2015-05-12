@$ = Meteor.npmRequire('NodObjC')
# uvcf = Meteor.npmRequire('uvcf')

# First you import the "Foundation" framework
$.framework 'Foundation'
$.framework 'Quartz'
$.framework 'AppKit'

# [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(foremostAppActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];

w = $.NSWorkspace('sharedWorkspace')
n = w('notificationCenter')
q = $.NSOperationQueue('mainQueue')

app = $.NSApplication('sharedApplication')

# s = $.NSSelectorFromString($())

# callback = ->
#   console.log "yoyoyoyo"

# wrapped = $(callback, $.NSObject)

# obj = $.NSObject('alloc')('init')

AppDelegate = $.NSObject.extend('AppDelegate')

AppDelegate.addMethod 'applicationChanged:', 'v@:@', (self, _cmd, notif) ->
  current = notif('object')('frontmostApplication')('localizedName').toString()
  Actions.setCurrentApplication current

# AppDelegate.addMethod 'applicationDidFinishLaunching:', 'v@:@', (self, _cmd, notif) ->
#   console.log('got applicationDidFinishLauching')
#   console.log(notif)

AppDelegate.addMethod 'applicationWillTerminate:', 'v@:@', (self, _cmd, notif) ->
  console.log('got applicationWillTerminate')
  console.log(notif)

# n('addObserverForName', $.NSWorkspaceDidActivateApplicationNotification, 'object', AppDelegate, 'queue', q, 'usingBlock', wrapped)


AppDelegate.register()

delegate = AppDelegate('alloc')('init')
app('setDelegate', delegate)

n('addObserver', delegate, 'selector', 'applicationChanged:', 'name', $('NSWorkspaceDidActivateApplicationNotification'), 'object', null )
# app('activateIgnoringOtherApps', true)
# shared('run')
# $.NSRunLoop('mainRunLoop')('run')

# console.log "i got here"

# Setup the recommended NSAutoreleasePool instance
# pool = $.NSAutoreleasePool('alloc')('init')
# NSStrings and JavaScript Strings are distinct objects, you must create an
# NSString from a JS String when an Objective-C class method requires one.
# string = $.NSString('stringWithUTF8String', 'Hello Objective-C World!')


# Print out the contents (toString() ends up calling [string description])
mask = $.NSAnyEventMask.toString()
mode = $('kCFRunLoopDefaultMode')

tock = ->
  ev = undefined
  while ev = app('nextEventMatchingMask', mask, 'untilDate', null, 'inMode', mode, 'dequeue', 1)
    app 'sendEvent', ev
  # app 'updateWindows'
  if true
    Meteor.setTimeout tock, 300
  # return

app 'finishLaunching'
# userInfo = $.NSDictionary('dictionaryWithObject', $(1), 'forKey', $('NSApplicationLaunchIsDefaultLaunchKey'))
# notifCenter = $.NSNotificationCenter('defaultCenter')
# notifCenter 'postNotificationName', $.NSApplicationDidFinishLaunchingNotification, 'object', app, 'userInfo', userInfo
@Actions = new OSX.Actions()

tock()

# ---
# generated by js2coffee 2.0.3

# Meteor.setTimeout ->
#   scrollUp()
# , 2000


# pool 'drain'

# eventHandler = $.NSEvent('addGlobalMonitorForEventsMatchingMask', $.NSMouseMovedMask, 'handler', )

# eventHandler = [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent * mouseEvent) {
#   NSLog(@"Mouse moved: %@", NSStringFromPoint([mouseEvent locationInWindow]));
# }];

# $.framework('Cocoa')

# app = $.NSApplication('sharedApplication')


# AppDelegate = $.NSObject.extend('AppDelegate')

# AppDelegate.addMethod 'applicationDidFinishLaunching:', 'v@:@', (self, _cmd, notif) ->
#   systemStatusBar = $.NSStatusBar('systemStatusBar')
#   statusMenu = systemStatusBar('statusItemWithLength', $.NSVariableStatusItemLength)
#   statusMenu('retain')
#   title = $.NSString('stringWithUTF8String', "Hello World")
#   statusMenu('setTitle', title)

# AppDelegate.register()

# delegate = AppDelegate('alloc')('init')
# app('setDelegate', delegate)

# app('activateIgnoringOtherApps', true)
# app('run')

# pool('release')


# server = http.createServer()
# server.listen '/var/tmp/voicecode.sock'

# server.on "request", ->
#   console.log "booom"
#   console.log 


net = Meteor.npmRequire("net")
fs = Meteor.npmRequire("fs")
socketPath = "/tmp/voicecode.sock"
socketPath2 = "/tmp/voicecode2.sock"

serverHandler = Meteor.bindEnvironment (localSerialConnection) ->
  localSerialConnection.on 'data', commandHandler

serverHandler2 = Meteor.bindEnvironment (localSerialConnection) ->
  localSerialConnection.on 'data', commandHandler2

previousPhrase = null

commandHandler = Meteor.bindEnvironment (data) ->
  body = data.toString('utf8')
  console.log body
  phrase = body.replace("\n", "")
  previousPhrase = phrase.toLowerCase().replace(/[\W]+/g, "")
  chain = new Commands.Chain(phrase + " ")
  results = chain.execute(true)

# comes from growl
commandHandler2 = Meteor.bindEnvironment (data) ->
  body = data.toString('utf8')
  console.log body
  phrase = body.replace("\n", "")
  console.log 
    previousPhrase: previousPhrase
    phrase: phrase.toLowerCase().replace(/[\W]+/g, "")
  if phrase.toLowerCase().replace(/[\W]+/g, "") != previousPhrase
    chain = new Commands.Chain(phrase + " ")
    results = chain.execute(true)

fs.stat socketPath, (err) ->
  if !err
    fs.unlinkSync socketPath
  unixServer = net.createServer serverHandler
  unixServer.listen socketPath

fs.stat socketPath2, (err) ->
  if !err
    fs.unlinkSync socketPath2
  unixServer2 = net.createServer serverHandler2
  unixServer2.listen socketPath2

# ---
# generated by js2coffee 2.0.3

# client = net.createConnection("/tmp/voicecode")

# client.on "connect", ->
#   console.log "connected"

# client.on "data", (data) ->
#   console.log "dataaaaaa"
#   console.log data