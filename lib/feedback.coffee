{CompositeDisposable} = require 'atom'
FeedbackAPI = null
Reporter = null

module.exports =
  config:
    alwaysShowInDevMode:
      type: 'boolean'
      default: false

  feedbackSource: 'survey-2015-1'

  activate: ->
    FeedbackAPI = require './feedback-api'

    @statusBarPromise = new Promise (resolve) =>
      @resolveStatusBarPromise = resolve

    @checkShouldRequestFeedback().then (shouldRequestFeedback) =>
      if shouldRequestFeedback
        Reporter ?= require './reporter'
        Reporter.sendEvent(@feedbackSource, 'did-show-status-bar-link')

        @addStatusBarItem()

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'feedback:show', => @showModal()
      else
        Reporter.sendEvent(@feedbackSource, 'did-finish-survey-activate')

  consumeStatusBar: (statusBar) ->
    @resolveStatusBarPromise(statusBar)

  consumeReporter: (realReporter) ->
    Reporter ?= require './reporter'
    Reporter.setReporter(realReporter)

  getStatusBar: ->
    @statusBarPromise

  addStatusBarItem: ->
    return if @statusBarTile?
    FeedbackStatusElement = require './feedback-status-element'
    workspaceElement = atom.views.getView(atom.workspace)

    @getStatusBar().then (statusBar) =>
      item = new FeedbackStatusElement()
      item.initialize({@feedbackSource})
      @statusBarTile = statusBar.addRightTile {item, priority: 200}

  showModal: ->
    unless @modal?
      FeedbackModalElement = require './feedback-modal-element'
      @modal = new FeedbackModalElement()
      @modal.initialize({@feedbackSource})
      @modal.onDidStartSurvey => @detectCompletedSurvey()
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

  detectCompletedSurvey: ->
    FeedbackAPI.detectDidCompleteFeedback(@feedbackSource).then =>
      Reporter.sendEvent(@feedbackSource, 'did-finish-survey')
      @statusBarTile.destroy()

  deactivate: ->
    @subscriptions?.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null
    @modal?.destroy()
    @modal = null
