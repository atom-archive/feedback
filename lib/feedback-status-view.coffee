{$, View} = require 'atom'

module.exports =
class FeedbackStatusView extends View
  @content: ->
    @a href: '#', class: 'feedback-status inline-block', tabindex: '-1', 'Send Feedback'

  initialize: ->
    @on 'click', =>
      atom.workspaceView.trigger 'feedback:report'
      false
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
