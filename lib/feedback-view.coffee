{View} = require 'atom'

module.exports =
class FeedbackView extends View
  @content: ->
    @div class: 'feedback overlay from-top', =>
      @h1 "Send us feedback"
      @div class: 'inset-panel', =>
        @textarea outlet: 'textarea', rows: 5, placeholder: "Let us know what we can do better."
        @div class: 'screenshot', =>
          @input id: 'screenshot', type: 'checkbox'
          @label for: 'screenshot', "Attach screenshot"
        @button class: 'btn', 'send'

  initialize: ->
    rootView.on 'core:cancel', => @destroy()
    rootView.prepend(this)
    @textarea.focus()

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      rootView.append(this)
