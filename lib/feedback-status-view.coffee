{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @div class: 'feedback-status inline-block', =>
     @span outlet: 'feedbackButton', type: 'button', class: 'icon icon-zap text-error'

  initialize: ->
    @feedbackButton.on 'click', => new FeedbackFormView()
    @feedbackButton.setTooltip("Frustrated? Happy? Annoyed? Let us know by clicking here!")
    @attach()

  attach: ->
    statusBarRight = atom.workspaceView.find('.status-bar-right')
    if statusBarRight.length == 0
      setTimeout((=> @attach()), 100) unless @detached
    else
      statusBarRight.append(this)

  detach: ->
    @detached = true
