{CompositeDisposable} = require 'atom'

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'feedback:show', => @showModal()
    @subscriptions.add atom.packages.onDidActivateInitialPackages => @addStatusBarItem()
    @subscriptions.add atom.packages.onDidActivatePackage (pack) =>
      @addStatusBarItem() if pack.name is 'status-bar'

  addStatusBarItem: ->
    return if @statusBarTile?
    FeedbackStatusElement = require './feedback-status-element'
    workspaceElement = atom.views.getView(atom.workspace)
    statusBar = workspaceElement.querySelector("status-bar")
    @statusBarTile = statusBar.addRightTile
      priority: 200
      item: new FeedbackStatusElement()

  showModal: ->
    unless @modal?
      FeedbackModalElement = require './feedback-modal-element'
      @modal = new FeedbackModalElement()
      @modal.initialize()
    @modal.show()

  deactivate: ->
    @subscriptions.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null
    @modal?.destroy()
    @modal = null
