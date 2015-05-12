Commands.createDisabled
  "sleepy time":
    description: "put dragon into sleep mode"
    tags: ["dragon"]
    action: (input) ->
      dictateName = Settings.localeSettings[Settings.locale].dragonApplicationName or "Dragon Dictate"
      @applescript """
      tell application "#{dictateName}"
        set microphone to sleep
      end tell
      """
  "wakeup":
    description: "put dragon into command mode if it is sleeping"
    tags: ["dragon"]
    action: (input) ->
      # dictateName = Settings.localeSettings[Settings.locale].dragonApplicationName or "Dragon Dictate"
      # @applescript """
      # tell application "#{dictateName}"
      #   set microphone to command operation
      # end tell
      # """
