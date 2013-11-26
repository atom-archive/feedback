{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @div class: 'feedback-status inline-block', =>
     @span outlet: 'feedbackButton', type: 'button', class: 'icon icon-zap text-error'

  initialize: ({@previouslyRun}) ->
    console.log @previouslyRun
    @feedbackButton.on 'click', => new FeedbackFormView()
    @feedbackButton.setTooltip("Frustrated? Happy? Annoyed? Let us know by clicking here!")
    @attach()

  attach: ->
    statusBarRight = atom.rootView.find('.status-bar-right')
    if statusBarRight.length == 0
      setTimeout((=> @attach()), 100)
    else
      statusBarRight.append(this)
