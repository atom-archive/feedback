{Emitter} = require 'atom'

Template = """
  <h1>Help Improve Atom</h1>
  <p>
    Our engineers and designers are interested in how you use Atom and where we
    can improve the experience.
  </p>
  <p>
    We'll share what we learn in a blog post.
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
