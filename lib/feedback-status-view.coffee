{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @span outlet: 'feedbackButton', type: 'button', class: 'feedback-status inline-block icon icon-zap text-warning'

  initialize: ->
    @on 'click', => new FeedbackFormView()
    @setTooltip("Frustrated? Happy? Annoyed? Let us know by clicking here!")
    @attach()

  attach: =>
    statusBar = atom.workspaceView.statusBar
    if statusBar
      statusBar.appendRight(this)
    else
      atom.packages.once('activated', @attach) unless @detached

  detach: ->
    @detached = true
