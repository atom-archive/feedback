FeedbackStatusView = require './feedback-status-view'
FeedbackFormView = null

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()
    atom.workspaceView.command 'feedback:report', =>
      FeedbackFormView ?= require './feedback-form-view'
      new FeedbackFormView()

  deactivate: ->
    @feedbackStatusView.remove()
