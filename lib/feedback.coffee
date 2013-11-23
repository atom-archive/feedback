FeedbackStatusView = require './feedback-status-view'

module.exports =
  activate: ->
    @addFeedbackView()

  deactivate: ->
    @feedbackStatusView.detach()

  addFeedbackView: ->
    statusBarRight = atom.rootView.find('.status-bar-right')
    if statusBarRight.length == 0
      setTimeout((=> @addFeedbackView()), 100)
    else
      @feedbackStatusView = new FeedbackStatusView()
      statusBarRight.append(@feedbackStatusView)
