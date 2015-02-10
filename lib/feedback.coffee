{CompositeDisposable} = require 'atom'
FeedbackAPI = null

module.exports =
  config:
    alwaysShowInDevMode:
      type: 'boolean'
      default: false

  feedbackSource: 'survey-2015-1'

  activate: ->
    FeedbackAPI = require './feedback-api'

    @checkShouldRequestFeedback().then (shouldRequestFeedback) =>
      return unless shouldRequestFeedback

      Reporter = require './reporter'
      Reporter.sendEvent('show-status-bar-link')

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
      @modal.initialize({@feedbackSource})
    @modal.show()

  checkShouldRequestFeedback: ->
    client = FeedbackAPI.getClientID()
    new Promise (resolve) =>
      shouldRequest = if atom.inSpecMode() or (atom.inDevMode() and atom.config.get('feedback.alwaysShowInDevMode'))
        true
      else if userId
        {crc32} = require 'crc'
        checksum = crc32(userId)
        checksum % 100 < 5
      else
        false

      if shouldRequest
        FeedbackAPI.fetchDidCompleteFeedback(@feedbackSource).then (didCompleteSurvey) ->
          resolve(not didCompleteSurvey)
      else
        resolve(false)

  deactivate: ->
    @subscriptions?.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null
    @modal?.destroy()
    @modal = null
