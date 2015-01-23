FeedbackStatusElement = require './feedback-status-element'

module.exports =
  activate: ->
    @subscriptions = atom.commands.add 'atom-workspace', 'feedback:show', ->
      console.log 'ok'

    atom.packages.once 'activated', =>
      item = new FeedbackStatusElement()
      statusBar = document.querySelector("status-bar")
      @statusBarTile = statusBar.addRightTile({item, priority: 200}) if statusBar?

  deactivate: ->
    @statusBarTile?.destroy()
    @subscriptions.dispose()
