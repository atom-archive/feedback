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
    @statusBarPromise = new Promise (resolve) =>
      @resolveStatusBarPromise = resolve

    process.nextTick =>
      FeedbackAPI = require './feedback-api'
      @checkShouldRequestFeedback().then (shouldRequestFeedback) =>
        Reporter ?= require './reporter'
        if shouldRequestFeedback
          @addStatusBarItem()
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add 'atom-workspace', 'feedback:show', => @showModal()
          Reporter.sendEvent('did-show-status-bar-link')

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
      @statusBarTile = statusBar.addRightTile {item, priority: -1}

  showModal: ->
    unless @modal?
      FeedbackModalElement = require './feedback-modal-element'
      @modal = new FeedbackModalElement()
      @modal.initialize({@feedbackSource})
      @modal.onDidStartSurvey => @detectCompletedSurvey()
    @modal.show()

  checkShouldRequestFeedback: ->
    client = FeedbackAPI.getClientID()
    FeedbackAPI.fetchSurveyMetadata(@feedbackSource).then (metadata) =>
      new Promise (resolve) =>
        shouldRequest = if atom.inSpecMode() or (atom.inDevMode() and atom.config.get('feedback.alwaysShowInDevMode'))
          true
        else if client
          {crc32} = require 'crc'
          checksum = crc32(client + @feedbackSource + metadata.display_seed)
          checksum % 100 < (metadata.display_percent ? 0)
        else
          false

        if shouldRequest
          FeedbackAPI.fetchDidCompleteFeedback(@feedbackSource).then (didCompleteSurvey) ->
            Reporter ?= require './reporter'
            Reporter.sendEvent('already-finished-survey') if didCompleteSurvey
            resolve(not didCompleteSurvey)
        else
          resolve(false)

  detectCompletedSurvey: ->
    FeedbackAPI.detectDidCompleteFeedback(@feedbackSource).then =>
      Reporter ?= require './reporter'
      Reporter.sendEvent('did-finish-survey')
      @statusBarTile.destroy()

  deactivate: ->
    @subscriptions?.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null
    @modal?.destroy()
    @modal = null
