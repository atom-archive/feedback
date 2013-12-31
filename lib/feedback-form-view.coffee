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
StoredFeedbackText = null

module.exports =
class FeedbackFormView extends View
  @content: ->
    @div class: 'feedback overlay from-top', =>
      @progress outlet: 'sendingStatus', class: 'sending-status initially-hidden', max: '100'

      @div outlet: 'inputForm', class: 'input', =>
        @h1 "Send us feedback"
        @p =>
          @span "This information will be posted publicly on "
          @a href: 'https://github.com/atom/atom/issues', 'the Atom repo.'

        @div class: 'block', =>
          @textarea outlet: 'feedbackText', class: 'native-key-bindings', rows: 5, placeholder: "Let us know what we can do better."

        @div class: 'block', =>
          @input outlet: 'username', type: 'text', class: 'native-key-bindings', placeholder: "GitHub username or email"
          @span outlet: 'signedInUsername', type: 'text', class: 'signed-in-user initially-hidden'

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
        @div =>
          @span "An issue was created: "
          @a outlet: 'issueLink', href:""

  initialize: ->
    @subscribe atom.workspaceView, 'core:cancel', => @detach()
    @subscribe @sendButton, 'click', => @send()

    @subscribe this, 'feedback:tab', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) + 1] ? @feedbackText).focus()

    @subscribe this, 'feedback:tab-previous', =>
      elements =  @find('input, textarea, button')
      (elements[elements.index(@find(':focus')) - 1] ? @sendButton).focus()

    @username.val atom.config.get('feedback.username')
    @fetchUser().then (user) => @setUser(user) if user

    @feedbackText.val(StoredFeedbackText) if StoredFeedbackText?
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
        atom.config.set('feedback.username', @username.val())
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

    @requestViaPromise(options, atom.getGitHubAuthToken()).then ({content}) => content.html_url

  postIssue: (imageUrl) ->
    token = atom.getGitHubAuthToken()

    data =
      title: @getTruncatedIssueTitle(@feedbackText.val())
      labels: ['feedback']
      body: """
        #{@feedbackText.val().trim()}

        Atom Version: #{atom.getVersion()}
        User Agent: #{navigator.userAgent}
      """

    data.body += "\nUser: @#{@username.val().trim().replace(/[@]+/g, '') ? 'unknown'}" unless token

    if imageUrl?
      imageUrl = imageUrl.replace("/blob/", '/raw/')
      data.body += "\nScreenshot: \n![screenshot](#{imageUrl})"

    if @attachDebugInfo.is(":checked")
      json = JSON.stringify(@captureDebugInfo(), null, 2)
      data.body += "\nDebug Info:\n```json\n#{json}\n```"

    options =
      url: 'https://api.github.com/repos/atom/atom/issues'
      method: "POST"
      json: true
      body: JSON.stringify(data)

    @requestViaPromise(options, token).then ({html_url}={}) => html_url

  setUser: (@user) ->
    atom.config.set('feedback.username', @user.login)
    @username.hide()
    @signedInUsername.text("GitHub issues will be created as @#{@user.login}").show()

  fetchUser: ->
    return Q() unless token = atom.getGitHubAuthToken()

    options =
      url: "https://api.github.com/user"
      json: true
      headers:
        'User-Agent': navigator.userAgent

    @requestViaPromise(options, token)

  requestViaPromise: (options, token) ->
    options.headers ?= {}
    options.headers['Authorization'] = "token #{token ? AtomBotToken}"
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
        deferred.reject("Failed")

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
