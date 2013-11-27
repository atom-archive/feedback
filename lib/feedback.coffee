FeedbackStatusView = require './feedback-status-view'
FeedbackFormView = require './feedback-form-view'

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()
    atom.workspaceView.command 'feedback:report', => new FeedbackFormView()

  deactivate: ->
    @feedbackStatusView.detach()
