Template = """
  <a href="#" class="inline-block">Help Improve Atom</a>
"""

module.exports =
class FeedbackStatusElement extends HTMLElement
  initialize: ({@feedbackSource}) ->

  attachedCallback: ->
    @innerHTML = Template
    atom.tooltips.add this, title: "Help us improve atom by giving feedback"
    @querySelector('a').addEventListener 'click', (e) =>
      Reporter = require './reporter'
      Reporter.sendEvent(@feedbackSource, 'did-click-status-bar-link')

      e.preventDefault()
      atom.commands.dispatch this, 'feedback:show'

module.exports = document.registerElement 'feedback-status',
  prototype: FeedbackStatusElement.prototype
