{$, View} = require 'atom'

module.exports =
class FeedbackInfoView extends View
  @content: ->
    @div tabindex: -1, class: 'feedback-info overlay from-top native-key-bindings', =>
      @h1 "Where to get support"
      @ul =>
        @li =>
          @span "If you have a feature request please start a Topic on the Atom forum "
          @a href: 'http://discuss.atom.io', 'http://discuss.atom.io'
          @span "."

        @li =>
          @span "Most of Atom's functionality comes from open sourced packages like "
          @a href: 'http://github.com/atom/find-and-replace', 'Find And Replace'
          @span " and "
          @a href: 'http://github.com/atom/settings-view', 'Settings'
          @span ". If you have a bug related to a package, create an issue on its GitHub repo. If you can't figure out which package to report the bug on search "
          @a href: 'https://atom.io/packages', 'https://atom.io/packages'
          @span " and follow the package's \"Bug\" link."

        @li =>
          @span "Your question might be answered in the "
          @a href: 'https://atom.io/faq', 'FAQ'
          @span "."

        @li =>
          @span "If your feedback doesn't fit into any of the above categories then click the Send Feedback button below."

      @div =>
        @button outlet: 'sendButton', class: 'btn btn-lg', 'Send Feedback'

  initialize: ->
    atom.workspaceView.prepend(this)

    @subscribe @sendButton, 'click', =>
      FeedbackFormView = require './feedback-form-view'
      new FeedbackFormView()

    @subscribe this, 'focusout', =>
      # during the focusout event body is the active element. Use nextTick to determine what the actual active element will be
      process.nextTick =>
        @detach() unless @is(':focus') or @find(':focus').length > 0
