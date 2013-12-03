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
      @progress outlet: 'sendingStatus', class: 'sending-status inline-block', max: '100'

      @div outlet: 'inputForm', class: 'input', =>
        @h1 "Send us feedback"
        @div class: 'details', =>
          @span "This information will be posted publicly on "
          @a href: 'https://github.com/atom/atom/issues', 'the Atom repo.'
        @div class: 'inset-panel', =>
          @textarea outlet: 'feedbackText', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."
          @input outlet: 'email', type: 'text', class: 'native-key-bindings', placeholder: "GitHub username or email"

          @div =>
            @input outlet: 'attachDebugInfo', class: 'native-key-bindings', id: 'attach-debug-info', type: 'checkbox'
            @label for: 'attach-debug-info', "Attach debug info (includes text of open buffers)"

          @div =>
            @input outlet: 'attachScreenshot', id: 'attach-screenshot', type: 'checkbox'
            @label for: 'attach-screenshot', "Attach screenshot"

          @button outlet: 'sendButton', class: 'btn', 'send'

          @div outlet: 'sendingError', class: 'sending-error'

      @div outlet: 'outputForm', tabindex: -1, class: 'output', =>
        @h1 "Thanks for the feedback!"
        @div =>
          @span "An issue was created "
          @a outlet: 'issueLink', href:""

  initialize: ->
    atom.workspaceView.on 'core:cancel', => @detach()
    @sendButton.on 'click', => @send()
    @on 'feedback:tab', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) + 1] ? @feedbackText).focus()

    @on 'feedback:tab-previous', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) - 1] ? @sendButton).focus()

    @email.val atom.config.get('feedback.email')
    atom.workspaceView.prepend(this)
    @feedbackText.focus()

  detatch: ->
    @off()
    super()

  send: ->
    @sendingError.hide()
    @sendButton.disable()
    @inputForm.hide()
    @sendingStatus.show()
    @sendingStatus.attr('value', 10)

    unless @feedbackText.val()
      @showError("You forgot to include your feedback")
      return

    Q("start") # Used to catch errors in first promise
      .then =>
        @captureScreenshot() if @attachScreenshot.is(":checked")
      .then (screenshot) =>
        @sendingStatus.attr('value', 50)
        @postScreenshot(screenshot) if screenshot
      .then (screenshotUrl) =>
        @sendingStatus.attr('value', 75)
        @postIssue(screenshotUrl)
      .then (issueUrl) =>
        @sendingStatus.attr('value', 100)
        @sendingStatus.hide()
        @issueLink.text issueUrl
        @issueLink.attr('href', issueUrl)
        atom.config.set('feedback.email', @email.val())
        @outputForm.show().focus().one 'blur', => @detach()
      .fail (error) =>
        @showError error?.responseJSON?.message ? error
        console.error error

  showError: (message) ->
    @inputForm.show()
    @sendingStatus.hide()
    @sendingError.show().text message
    @sendButton.enable()

  postScreenshot: (screenshot) ->
    guid = Guid.raw()
    options =
      url: "https://api.github.com/repos/atom/feedback-storage/contents/image-#{guid}.png"
      method: 'PUT'
      json: true
      body:
        message: "Add image (#{guid})"
        content: screenshot.toString('base64')

    @requestViaPromise(options).then ({content}) => content.html_url

  postIssue: (imageUrl) ->
    data =
      title: @feedbackText.val()[0..50]
      labels: 'feedback'
      body: """
        #{@feedbackText.val()}

        User: @#{@email.val() ? 'unknown'}
        Atom Version: #{atom.getVersion()}
        User Agent: #{navigator.userAgent}
      """

    data.body += "\nScreenshot: [screenshot](#{imageUrl})" if imageUrl?
    if @attachDebugInfo.is(":checked")
      json = JSON.stringify(@captureDebugInfo(), null, 2)
      data.body += "\nDebug Info:\n```json\n#{json}\n```"

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
