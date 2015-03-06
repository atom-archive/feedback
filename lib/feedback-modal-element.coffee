{Emitter} = require 'atom'

Template = """
  <h1>Help us improve Atom!</h1>
  <p>
    Would you mind taking a minute or two to answer a few questions
    about your experience with Atom?
  </p>
  <p>
    Your feedback is very important to us!
  </p>
  <div class="btn-toolbar">
    <a href="{{SurveyURL}}" class="btn btn-primary">Take the short survey</a>
    <a href="#" class="btn btn-cancel">Not right now</a>
  </div>
"""

module.exports =
class FeedbackModalElement extends HTMLElement
  initialize: ({feedbackSource}) ->
    @emitter = new Emitter
    Reporter = require './reporter'
    FeedbackAPI = require './feedback-api'

    @innerHTML = Template.replace('{{SurveyURL}}', FeedbackAPI.getSurveyURL(feedbackSource))
    @querySelector('.btn-primary').addEventListener 'click', =>
      Reporter.sendEvent('did-click-modal-cta')
      @emitter.emit('did-start-survey')
      @hide()
    @querySelector('.btn-cancel').addEventListener 'click', =>
      Reporter.sendEvent('did-click-modal-cancel')
      @hide()

  onDidStartSurvey: (callback) ->
    @emitter.on 'did-start-survey', callback

  show: ->
    @modalPanel ?= atom.workspace.addModalPanel(item: this)
    @modalPanel.show()

  hide: ->
    @modalPanel.hide()

  destroy: ->
    @modalPanel?.destroy()
    @modalPanel = null
    @emitter.dispose()

module.exports = document.registerElement 'feedback-modal',
  prototype: FeedbackModalElement.prototype
