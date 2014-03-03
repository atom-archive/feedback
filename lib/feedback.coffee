FeedbackStatusView = require './feedback-status-view'
FeedbackInfoView = null

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()
    atom.workspaceView.command 'feedback:report', =>
      FeedbackInfoView ?= require './feedback-info-view'
      new FeedbackInfoView()

  deactivate: ->
    @feedbackStatusView.remove()
