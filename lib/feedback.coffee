{CompositeDisposable} = require 'atom'
FeedbackStatusElement = require './feedback-status-element'

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'feedback:show', ->
      console.log 'ok'

    @subscriptions.add atom.packages.onDidActivateInitialPackages => @addStatusBarItem()
    @subscriptions.add atom.packages.onDidActivatePackage (pack) =>
      @addStatusBarItem() if pack.name is 'status-bar'

  addStatusBarItem: ->
    workspaceElement = atom.views.getView(atom.workspace)
    statusBar = workspaceElement.querySelector("status-bar")
    if statusBar?
      item = new FeedbackStatusElement()
      @statusBarTile = statusBar.addRightTile({item, priority: 200})

  deactivate: ->
    @statusBarTile?.destroy()
    @subscriptions.dispose()
