{$, View} = require 'atom'
FeedbackFormView = require './feedback-form-view'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @a href: '#', class: 'feedback-status inline-block', tabindex: '-1', 'Send Feedback'

  initialize: ->
    @on 'click', => new FeedbackFormView(); false
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
