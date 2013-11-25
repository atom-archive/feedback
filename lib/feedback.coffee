FeedbackStatusView = require './feedback-status-view'

module.exports =
  activate: ->
    @addFeedbackView()

  deactivate: ->
    @feedbackStatusView.detach()

  addFeedbackView: ->
    new FeedbackStatusView()
