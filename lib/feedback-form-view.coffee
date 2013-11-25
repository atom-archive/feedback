{_, $, fs, View} = require 'atom'
path = require 'path'
{Buffer} = require 'buffer'
{exec} = require 'child_process'
temp = require 'temp'
Q = require 'q'
Guid = require 'guid'

AtomBotToken = "362295be4c5258d3f7b967bbabae662a455ca2a7"

module.exports =
class FeedbackFormView extends View
  @content: ->
    @div class: 'feedback overlay from-top', =>
      @div class: 'screenshot-status', =>
        @span class: 'text-info', 'Taking screenshot.'
      @div class: 'input', =>
        @h1 "Send us feedback"
        @div class: 'inset-panel', =>
          @textarea outlet: 'textarea', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."
          @input outlet: 'attachDebugInfo', id: 'attach-debug-info', type: 'checkbox'
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
    atom.rootView.on 'core:cancel', => @detach()
    @attachScreenshot.on 'click', => @toggleScreenshot()
    @attachDebugInfo.on 'click', => @toggleDebugInfo()
    @sendButton.on 'click', => @send()

    @toggleScreenshot()
    @toggleDebugInfo()

    atom.rootView.prepend(this)
    @textarea.focus()

  send: ->
    @sendButton.disable()
    @sendingStatus.show()
    @sendingError.hide()
    @sendingStatus.attr('value', 0)

    unless @textarea.val()
      @showError("You forgot to include your feedback")
      return

    failureMessage = null
    Q("start") # Used to catch errors in uploadScreenshot
      .then =>
        @uploadScreenshot()
        @sendingStatus.attr('value', 50)
      .then =>
        @createIssue(arguments...)
        @sendingStatus.attr('value', 100)
      .then (url) =>
        @find('.input').hide()
        @find('.output').show().focus().on 'blur', => @detach()
        @issueLink.text url
        @issueLink.attr('href', url)
      .fail (error) =>
        @showError error?.responseJSON?.message ? error

  showError: (message) ->
    @sendingError.show().text message
    @sendButton.enable()
    @sendingStatus.hide()

  uploadScreenshot: ->
    return Q() unless @screenshot

    guid = Guid.raw()
    ajaxOptions =
      url: "https://api.github.com/repos/atom/feedback-storage/contents/image-#{guid}.png"
      type: 'PUT'
      data:
        message: "Add image (#{guid})"
        content: @screenshot.toString('base64')

    @ajax(ajaxOptions).then ({content}) ->
      {imageUrl: content.html_url}

  createIssue: ({imageUrl, debugInfoUrl}={}) ->
    data =
      title: @textarea.val()[0..50]
      labels: 'feedback'
      body: """
        #{@textarea.val()}

        User: #{process.env['USER']}
        Atom Version: #{atom.getVersion()}
        User Agent: #{navigator.userAgent}
      """

    data.body += "\nScreenshot: [screenshot](#{imageUrl})" if imageUrl?
    data.body += "\nDebug Info:\n```json\n#{@debugInfo}\n```" if @debugInfo?

    ajaxOptions =
      url: 'https://api.github.com/repos/atom/feedback-storage/issues'
      type: 'POST'
      dataType: 'json'
      data: data

    @ajax(ajaxOptions).then ({html_url}) ->
      html_url

  ajax: (options) ->
    options.dataType ?= 'json'
    options.beforeSend ?= (xhr) ->
      xhr.setRequestHeader('Authorization', "bearer #{AtomBotToken}")
    options.data = JSON.stringify(options.data)

    Q($.ajax(options))

  toggleScreenshot: ->
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

  toggleDebugInfo: ->
    enabled = @attachDebugInfo.is(":checked")
    if enabled
      @debugInfo = JSON.stringify(@captureDebugInfo(), null, 2)
    else
      @debugInfo = null

  captureDebugInfo: ->
    activeView = atom.rootView.getActiveView()
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
