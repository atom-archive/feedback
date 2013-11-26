FeedbackStatusView = require './feedback-status-view'

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()

  deactivate: ->
    @feedbackStatusView.detach()
