pack = Packages.register
  name: 'safari'
  platforms: ['darwin']
  description: 'Safari integration'
  applications: ['com.apple.Safari']

Settings.extend 'browserApplications', pack.applications()

pack.before
  'object.forward': ->
    @key ']', 'command'
  'object.backward': ->
    @key '[', 'command'
  'object.refresh': ->
    @key 'R', 'command'

pack.commands
  'show-tabs':
    spoken: 'show tabs'
    description: 'show all the tabs open in safari'
    action: (input) ->
      @key '\\', 'command shift'

Events.on 'getCurrentBrowserUrl', (container={}) ->
  if Scope.active 'safari'
    container.url = Applescript """
      tell application "Safari" to return URL of front document as string
    """, {async: false}
    container.continue = false
    container
