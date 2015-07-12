Meteor.startup ->
  console.log "Copyright (c) VoiceCode.io 2015 - all rights reserved"
  
  @Grammar = new Grammar()
  @alphabet = new Alphabet()
  repetition = new Repetition()
  @modifiers = new Modifiers()
  @enabledCommandsManager = new EnabledCommandsManager()
  @vocabulary = new Vocabulary()
  Commands.loadConditionalModules(enabledCommandsManager.settings)
  modifiers.checkVocabulary()
  @ParseGenerator = {}
  Commands.reloadGrammar()
  @synchronizer = new Synchronizer()
  synchronizer.updateAllCommands(true)
