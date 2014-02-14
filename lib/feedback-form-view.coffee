{_, $, fs, View} = require 'atom'
path = require 'path'
{Buffer} = require 'buffer'
{exec} = require 'child_process'
temp = require 'temp'
Q = require 'q'
Guid = require 'guid'

AtomBotToken = "362295be4c5258d3f7b967bbabae662a455ca2a7"
AtomBotUserId = "1534652"
StoredFeedbackText = null

module.exports =
class FeedbackFormView extends View
  @content: ->
    @div tabindex: -1, class: 'feedback overlay from-top', =>
      @progress outlet: 'sendingStatus', class: 'sending-status initially-hidden', max: '100'

      @div outlet: 'inputForm', class: 'input', =>
        @h1 "Send us feedback"
        @p =>
          @span "This information will be posted publicly on "
          @a href: 'https://github.com/atom/atom/issues', 'the Atom repo.'

        @div class: 'block', =>
          @textarea outlet: 'feedbackText', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."

        @div class: 'block', =>
          @input outlet: 'emailAddress', type: 'text', class: 'native-key-bindings', placeholder: "Email Address"

        @div class: 'block', =>
          @div =>
            @input outlet: 'attachDebugInfo', class: 'native-key-bindings', id: 'attach-debug-info', type: 'checkbox'
            @label for: 'attach-debug-info', "Attach debug info (includes text of open buffers)"

          @div =>
            @input outlet: 'attachScreenshot', id: 'attach-screenshot', type: 'checkbox'
            @label for: 'attach-screenshot', "Attach screenshot"

        @div =>
          @button outlet: 'sendButton', class: 'btn btn-lg', 'Send Feedback'

        @div outlet: 'sendingError', class: 'sending-error block initially-hidden'

      @div outlet: 'outputForm', tabindex: -1, class: 'output initially-hidden', =>
        @h1 "Thanks for the feedback!"

  initialize: ->
    @subscribe @sendButton, 'click', => @send()
    @subscribe atom.workspaceView, 'core:cancel', => @detach()
    @subscribe this, 'focusout', =>
      # durring the focusout event body is the active element. Use nextTick to determine what the actual active element will be
      process.nextTick =>
        @detach() unless @is(':focus') or @find(':focus').length > 0

    @subscribe this, 'feedback:tab', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) + 1] ? @feedbackText).focus()

    @subscribe this, 'feedback:tab-previous', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) - 1] ? @sendButton).focus()

    @emailAddress.val atom.config.get('feedback.emailAddress')

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
    @inputForm.hide()
    @sendingStatus.show()
    @sendingStatus.attr('value', 10)

    unless @feedbackText.val().trim()
      @showError("You forgot to include your feedback")
      return Q("")

    Q("start") # Used to catch errors in first promise
      .then =>
        @captureScreenshot() if @attachScreenshot.is(":checked")
      .then (screenshot) =>
        @sendingStatus.attr('value', 50)
        @sendEmail(screenshot)
      .then =>
        @feedbackText.val(null)
        @sendingStatus.attr('value', 100)
        @sendingStatus.hide()
        atom.config.set('feedback.emailAddress', @emailAddress.val())
        @outputForm.show().focus().one 'blur', => @detach()
      .fail (error) =>
        @showError error?.responseJSON?.message ? error
        console.error error

  showError: (message) ->
    @inputForm.show()
    @sendingStatus.hide()
    @sendingError.show().text message
    @sendButton.enable()

  sendEmail: (screenshot) ->
    mail = require('nodemailer')

    mailOptions =
      from: @emailAddress.val().trim()
      to: 'atom@github.com'
      subject: "Feedback: " + @feedbackText.val().trim()
      text: """
        #{@feedbackText.val().trim()}

        Atom Version: #{atom.getVersion()}
        User Agent: #{navigator.userAgent}
      """

    if screenshot
      mailOptions.attachments = [{
        fileName: 'screenshot.png'
        contents: screenshot
      }]

    if @attachDebugInfo.is(":checked")
      json = JSON.stringify(@captureDebugInfo(), null, 2)
      mailOptions.text += "\nDebug Info:\n```json\n#{json}\n```"

    deferred = Q.defer()
    mail.createTransport('direct').sendMail mailOptions, (error, response) ->
      if error?
        deferred.reject(error)
      else
        deferred.resolve(response)
    deferred.promise

  getTruncatedIssueTitle: (text) ->
    MAX = 100
    lines = text.trim().split('\n')
    title = lines?[0] or ''
    if title.length > MAX
      words = title[0..MAX].split(/[ ]+/g)
      words.pop() # remove the last word cause it was probably truncated
      title = words.join(' ').trim()
    title

  captureScreenshot: (callback) ->
    deferred = Q.defer()
    process.nextTick =>
      atom.getCurrentWindow().capturePage (data) =>
        deferred.resolve(data)
    deferred.promise

  captureDebugInfo: ->
    activeView = atom.workspaceView.getActiveView()
    return {} unless activeView?.firstRenderedScreenRow?
    editor = activeView

    renderedLines = _.map editor.renderedLines.find('.line'), (el, index) -> "#{editor.firstRenderedScreenRow + index}: #{el.innerText}"
    displayBufferLines = editor.linesForScreenRows(0, editor.getLastScreenRow()).map (screenLine, row) -> "#{row}: #{screenLine.text}"
    bufferLines = [0..editor.getLastBufferRow()].map (row) -> "#{row}: #{editor.lineForBufferRow(row)}"

    editorView:
      firstRenderedScreenRow: editor.firstRenderedScreenRow
      lastRenderedScreenRow: editor.lastRenderedScreenRow
      renderedLines: renderedLines
      displayBufferLines: displayBufferLines
      bufferLines: bufferLines
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
      "file: #{Math.round(stats.size / 1024)}kB"
    else if stats.isSymbolicLink()
      fs.readlinkSync(filepath)
