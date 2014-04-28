FeedbackStatusView = require './feedback-status-view'
FeedbackView = null

module.exports =
  activate: ->
    @feedbackStatusView = new FeedbackStatusView()
    atom.workspaceView.command 'feedback:show', ->
      FeedbackView ?= require './feedback-view'
      new FeedbackView()

  deactivate: ->
    @feedbackStatusView.remove()
