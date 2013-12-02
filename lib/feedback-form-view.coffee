{_, $, fs, View} = require 'atom'
path = require 'path'
{Buffer} = require 'buffer'
{exec} = require 'child_process'
temp = require 'temp'
Q = require 'q'
Guid = require 'guid'
request = require 'request'

AtomBotToken = "362295be4c5258d3f7b967bbabae662a455ca2a7"
AtomBotUserId = "1534652"

module.exports =
class FeedbackFormView extends View
  @content: ->
    @div class: 'feedback overlay from-top', =>
      @div class: 'screenshot-status', =>
        @span class: 'text-info', 'Taking screenshot.'

      @div class: 'input', =>
        @h1 "Send us feedback"
        @div class: 'inset-panel', =>
          @textarea outlet: 'feedbackText', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."
          @input outlet: 'email', type: 'text', class: 'native-key-bindings', placeholder: "GitHub username or email"
          @input outlet: 'attachDebugInfo', class: 'native-key-bindings', id: 'attach-debug-info', type: 'checkbox'
          @label for: 'attach-debug-info', "Attach debug info (includes text of open buffers)"

          @div class: 'screenshot', =>
            @input outlet: 'attachScreenshot', id: 'attach-screenshot', type: 'checkbox'
            @label for: 'attach-screenshot', "Attach screenshot"
            @img outlet: 'screenshotImage'
          @button outlet: 'sendButton', class: 'btn', 'send'
          @progress outlet: 'sendingStatus', class: 'sending-status inline-block', max: '100'

          @div outlet: 'sendingError', class: 'sending-error'

      @div tabindex: -1, class: 'output', =>
        @h1 "Thanks for the feedback!"
        @div =>
          @span "An issue was created "
          @a outlet: 'issueLink', href:""

  initialize: ->
    atom.workspaceView.on 'core:cancel', => @detach()
    @attachScreenshot.on 'click', => @updateScreenshot()
    @attachDebugInfo.on 'click', => @updateDebugInfo()
    @sendButton.on 'click', => @send()

    @email.val atom.config.get('feedback.email')
    atom.workspaceView.prepend(this)
    @feedbackText.focus()

  send: ->
    @sendButton.disable()
    @sendingStatus.show()
    @sendingError.hide()
    @sendingStatus.attr('value', 0)

    unless @feedbackText.val()
      @showError("You forgot to include your feedback")
      return

    failureMessage = null
    Q("start") # Used to catch errors in uploadScreenshot
      .then =>
        @sendingStatus.attr('value', 50)
        @uploadScreenshot()
      .then =>
        @sendingStatus.attr('value', 100)
        @createIssue(arguments...)
      .then (url) =>
        @find('.input').hide()
        @find('.output').show().focus().on 'blur', => @detach()
        @issueLink.text url
        @issueLink.attr('href', url)
        atom.config.set('feedback.email', @email.val())
      .fail (error) =>
        console.error error
        @showError error?.responseJSON?.message ? error

  showError: (message) ->
    @sendingError.show().text message
    @sendButton.enable()
    @sendingStatus.hide()

  uploadScreenshot: ->
    return Q() unless @screenshot

    guid = Guid.raw()
    options =
      url: "https://api.github.com/repos/atom/feedback-storage/contents/image-#{guid}.png"
      method: 'PUT'
      json: true
      body:
        message: "Add image (#{guid})"
        content: @screenshot.toString('base64')

    @requestViaPromise(options).then ({content}) => content.html_url

  createIssue: (imageUrl) ->
    data =
      title: @feedbackText.val()[0..50]
      labels: 'feedback'
      body: """
        #{@feedbackText.val()}

        User: #{@email.val() ? 'unknown'}
        Atom Version: #{atom.getVersion()}
        User Agent: #{navigator.userAgent}
      """

    data.body += "\nScreenshot: [screenshot](#{imageUrl})" if imageUrl?
    data.body += "\nDebug Info:\n```json\n#{@debugInfo}\n```" if @debugInfo?

    options =
      url: 'https://api.github.com/repos/atom/atom/issues'
      method: "POST"
      json: true
      body: JSON.stringify(data)

    @requestViaPromise(options).then ({html_url}={}) => html_url

  requestViaPromise: (options) ->
    options.headers ?= {}
    options.headers['Authorization'] = "token #{AtomBotToken}"
    options.headers['User-Agent'] = "Atom"

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
        deferred.reject("Failed")

    deferred.promise

  updateScreenshot: ->
    enabled = @attachScreenshot.is(":checked")
    @screenshotImage.hide()
    @screenshot = null
    return unless enabled

    Q("start")
      .then =>
        @captureScreenshot()
      .then (data) =>
        @screenshot = data
        @screenshotImage.show()
        @screenshotImage[0].src = "data:image/png;base64," + @screenshot.toString('base64')
      .fail (error) =>
        @showError.show("Failed to take screenshot")

  captureScreenshot: (callback) ->
    deferred = Q.defer()
    $('.screenshot-status').show()
    $('.input').hide()
    process.nextTick =>
      atom.getCurrentWindow().capturePage (data) =>
        $('.screenshot-status').hide()
        $('.input').show()
        deferred.resolve(data)
    deferred.promise

  updateDebugInfo: ->
    enabled = @attachDebugInfo.is(":checked")
    if enabled
      @debugInfo = JSON.stringify(@captureDebugInfo(), null, 2)
    else
      @debugInfo = null

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
