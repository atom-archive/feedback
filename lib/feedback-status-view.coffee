{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @div class: 'feedback-status inline-block', =>
     @span outlet: 'feedbackButton', type: 'button', class: 'icon icon-zap text-error'

  initialize: (firstRun) ->
    new FeedbackFormView()
    @feedbackButton.on 'click', => new FeedbackFormView()
    @feedbackButton.setTooltip("Frustrated? Happy? Annoyed? Let us know by clicking here!")
    @attach()

  showTooltip: ->
    if not firstRun?
      @feedbackButton.tooltip('show')
      $(window).one 'click', => @feedbackButton.tooltip('hide')
      atom.rootView.one 'core:cancel', => @feedbackButton.tooltip('hide')

  attach: ->
    statusBarRight = atom.rootView.find('.status-bar-right')
    if statusBarRight.length == 0
      setTimeout((=> @attach()), 100)
    else
      statusBarRight.append(this)
      setTimeout((=> @showTooltip()), 1000)
