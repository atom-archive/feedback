FeedbackView = require './feedback-view'

module.exports =
  feedbackView: null

  activate: ->
    @feedbackView = new FeedbackView

  deactivate: ->
    @feedbackView.destroy()
