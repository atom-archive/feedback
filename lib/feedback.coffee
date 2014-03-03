FeedbackStatusView = require './feedback-status-view'
SupportInfoView = null

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()
    atom.workspaceView.command 'feedback:report', =>
      SupportInfoView ?= require './feedback-info-view'
      new SupportInfoView()

  deactivate: ->
    @feedbackStatusView.remove()
