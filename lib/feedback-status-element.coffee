Template = """
  <a href="#" class="inline-block">Share Feedback on Atom</a>
"""

module.exports =
class FeedbackStatusElement extends HTMLElement
  initialize: ({@feedbackSource}) ->

  attachedCallback: ->
    @innerHTML = Template
    atom.tooltips.add this, title: "Help us improve Atom by giving feedback"
    @querySelector('a').addEventListener 'click', (e) =>
      Reporter = require './reporter'
      Reporter.sendEvent('did-click-status-bar-link')

      e.preventDefault()
      atom.commands.dispatch this, 'feedback:show'

module.exports = document.registerElement 'feedback-status',
  prototype: FeedbackStatusElement.prototype
