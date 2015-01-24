Template = """
  <h1>Help us improve Atom!</h1>
  <p>
    Would you mind taking a minute to answer a few questions
    about your experience with Atom?
  </p>
  <p>
    Your feedback will help us improve Atom by understanding how you use Atom
    and what you expect from it.
  </p>
  <div class="btn-toolbar">
    <a href="#" class="btn btn-primary">Take the 1 minute survey</a>
    <a href="#" class="btn btn-cancel">Not right now</a>
  </div>
"""

module.exports =
class FeedbackModalElement extends HTMLElement
  initialize: ->
    @innerHTML = Template
    @querySelector('.btn-primary').addEventListener 'click', => @hide()
    @querySelector('.btn-cancel').addEventListener 'click', => @hide()

  show: ->
    @modalPanel ?= atom.workspace.addModalPanel(item: this)
    @modalPanel.show()

  hide: ->
    @modalPanel.hide()

  destroy: ->
    @modalPanel?.destroy()
    @modalPanel = null

module.exports = document.registerElement 'feedback-modal',
  prototype: FeedbackModalElement.prototype
