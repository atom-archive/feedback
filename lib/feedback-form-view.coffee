fs = require 'fs'
path = require 'path'

{$, View} = require 'atom'
Q = require 'q'
request = require 'request'

StoredFeedbackText = null

module.exports =
class FeedbackFormView extends View
  @content: ->
    @div tabindex: -1, class: 'feedback overlay from-top', =>
      @div outlet: 'inputForm', class: 'input', =>
        @h1 "Send us feedback"
        @p =>
          @span "This information will be sent to "
          @a href: 'mailto:support@atom.io', 'atom@github.com'

        @div class: 'block', =>
          @textarea outlet: 'feedbackText', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."

        @div class: 'block', =>
          @input outlet: 'email', type: 'text', class: 'native-key-bindings', placeholder: "Email Address (required)"
          @span type: 'text', class: 'initially-hidden'

        @div class: 'block', =>
          @div =>
            @input outlet: 'attachDebugInfo', class: 'native-key-bindings', id: 'attach-debug-info', type: 'checkbox'
            @label for: 'attach-debug-info', "Attach debug info (includes text of open buffers)"

        @div =>
          @button outlet: 'sendButton', class: 'btn btn-lg', 'Send Feedback'

        @div outlet: 'sendingError', class: 'sending-error block initially-hidden'

      @div outlet: 'outputForm', tabindex: -1, class: 'output initially-hidden', =>
        @h1 "Thanks for the feedback!"
        @div =>
          @span "An email was sent to "
          @a href: 'mailto:atom@github.com', 'atom@github.com'

  initialize: ->
    @subscribe @sendButton, 'click', => @send()
    @subscribe this, 'feedback:send', => @send()
    @subscribe atom.workspaceView, 'core:cancel', => @detach()
    @subscribe this, 'focusout', =>
      # during the focusout event body is the active element. Use nextTick to determine what the actual active element will be
      process.nextTick =>
        @detach() unless @is(':focus') or @find(':focus').length > 0

    @subscribe this, 'feedback:tab', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) + 1] ? @feedbackText).focus()

    @subscribe this, 'feedback:tab-previous', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) - 1] ? @sendButton).focus()

    @email.val atom.config.get('feedback.email')

    @feedbackText.val(StoredFeedbackText)
    atom.workspaceView.prepend(this)
    @feedbackText.focus()

  detach: ->
    StoredFeedbackText = @feedbackText.val()
    @unsubscribe()
    atom.workspaceView.focus()
    super()

  send: ->
    @sendingError.hide()
    @sendButton.disable()
    @focus()

    unless @feedbackText.val().trim()
      @showError("Please enter your feedback")
      return Q("")

    unless @email.val().trim()
      @showError("Please enter your email address")
      return Q("")

    unless /\S+@\S+/.test(@email.val())
      @showError("'#{@email.val()}' is not a valid email address")
      return Q("")

    Q("start") # Used to catch errors in first promise
      .then =>
        @postFeedback()
      .then =>
        atom.config.set('feedback.email', @email.val())
        @feedbackText.val(null)
        @inputForm.hide()
        @outputForm.show().focus().one 'blur', => @detach()
      .fail (error) =>
        @showError error?.responseJSON?.message ? error

  showError: (message) ->
    console.error message
    @sendingError.show().text message
    @sendButton.enable()

  postFeedback: ->
    data =
      email: @email.val().trim()
      body: @feedbackText.val().trim()
      version: atom.getVersion()
      userAgent: navigator.userAgent

    data.debugInfo = JSON.stringify(@captureDebugInfo(), null, 2) if @attachDebugInfo.is(":checked")

    options =
      url: 'https://atom.io/api/feedback'
      method: "POST"
      json: true
      body: data

    @requestViaPromise(options)

  requestViaPromise: (options) ->
    options.headers ?= {}
    options.headers['User-Agent'] = navigator.userAgent

    deferred = Q.defer()
    request options, (error, response, body) =>
      if error
        deferred.reject(error)
      else if body
        if body.errors?
          deferred.reject(body.errors[0].message)
        else
          deferred.resolve(body)
      else
        deferred.reject("Failed: " + response?.statusMessage)

    deferred.promise

  captureDebugInfo: ->
    editor = atom.workspace.getActiveEditor()
    return {} unless editor

    bufferLines: [0..editor.getLastBufferRow()].map (row) -> "#{row}: #{editor.lineForBufferRow(row)}"
    dotAtom: @directoryToObject(atom.config.configDirPath)

  directoryToObject: (filepath) ->
    stats = fs.lstatSync(filepath)
    name = path.basename(filepath)

    if stats.isDirectory()
      results = {}
      fs.readdirSync(filepath).forEach (subpath) =>
        return if /^\./.test subpath
        results[subpath] = @directoryToObject(path.join(filepath, subpath))
      results
    else if stats.isFile()
      kilobytes = Math.round(stats.size / 1024)
      if kilobytes == 0
        "file: #{stats.size}B"
      else
        "file: #{kilobytes}kB"
    else if stats.isSymbolicLink()
      fs.readlinkSync(filepath)
