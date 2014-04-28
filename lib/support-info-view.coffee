{$, View} = require 'atom'

module.exports =
class SupportInfoView extends View
  @content: ->
    @div tabindex: -1, class: 'support-info overlay from-top native-key-bindings', =>
      @h1 "Where to get support"
      @ul =>
        @li =>
          @span class: 'text-highlight', "Found a Bug?"
          @span " Most of Atom's functionality comes from open source packages (e.g. "
          @a href: 'http://github.com/atom/find-and-replace', 'Find And Replace'
          @span " and "
          @a href: 'http://github.com/atom/settings-view', 'Settings'
          @span ".) "
          @a href: 'https://atom.io/packages', 'Find the related package'
          @span " and create an issue on the package's GitHub repo that describes how to reproduce the bug."

        @li =>
          @span class: 'text-highlight', "Feature Request?"
          @span " Start a Topic on the "
          @a href: 'http://discuss.atom.io', 'Atom forum'
          @span "."

        @li =>
          @span "Check the "
          @a href: 'https://atom.io/faq', 'FAQ'
          @span "."

        @li =>
          @span "If your feedback doesn't fit into any of the above categories then click the Send Feedback button below."

  initialize: ->
    atom.workspaceView.prepend(this)

    @subscribe this, 'focusout', =>
      # during the focusout event body is the active element. Use nextTick to determine what the actual active element will be
      process.nextTick =>
        @detach() unless @is(':focus') or @find(':focus').length > 0

    @subscribe atom.workspaceView, 'core:cancel', => @detach()

    @focus()
