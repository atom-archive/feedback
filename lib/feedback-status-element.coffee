Template = """
  <a href="#" class="inline-block">1-minute survey</a>
"""

module.exports =
class FeedbackStatusElement extends HTMLElement
  initialize: ({@feedbackSource}) ->

  attachedCallback: ->
    @innerHTML = Template
    atom.tooltips.add this, title: "Help us improve Atom by giving feedback"

    unless localStorage.getItem("hasClickedSurveyLink-#{@feedbackSource}")
      @classList.add 'promote'

    @querySelector('a').addEventListener 'click', (e) =>
      localStorage.setItem("hasClickedSurveyLink-#{@feedbackSource}", true)
      @classList.remove 'promote'

      Reporter = require './reporter'
      Reporter.sendEvent('did-click-status-bar-link')

      e.preventDefault()
      atom.commands.dispatch this, 'feedback:show'

module.exports = document.registerElement 'feedback-status',
  prototype: FeedbackStatusElement.prototype
