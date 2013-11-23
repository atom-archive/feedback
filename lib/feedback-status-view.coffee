{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @div class: 'feedback-status inline-block', =>
     @span outlet: 'feedback', type: 'button', class: 'icon icon-zap text-error'

  initialize: (firstRun) ->
    @feedback.setTooltip("Frustrated? Happy? Annoyed? Let us know by clicking here!")
    if not firstRun?
      setTimeout((=> @feedback.tooltip('show')), 1000)
      setTimeout((=> @feedback.tooltip('hide')), 10000)

    @feedback.on 'click', =>
      new FeedbackFormView()
