{$, WorkspaceView} = require 'atom'
Q = require 'q'
FeedbackFormView = require '../lib/feedback-form-view'

describe "Feedback", ->
  [form, fetchUserDeferred] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.packages.activatePackage('feedback')

    fetchUserDeferred = Q.defer()
    spyOn(FeedbackFormView.prototype, 'fetchUser').andReturn(fetchUserDeferred.promise)

    form = new FeedbackFormView

  it "displays the feedback form", ->
    expect(atom.workspaceView.find('.feedback')).toExist()

  it "maintains feedback values between toggles", ->
    form.feedbackText.val('who wants to live forever')
    form.trigger 'core:cancel'
    form = new FeedbackFormView
    expect(form.feedbackText.val()).toBe 'who wants to live forever'

  it "uses the username from the website when logged in", ->
    expect(form.username.val()).toBe ''
    fetchUserDeferred.resolve(login: 'omgthatguy')

    waitsForPromise -> fetchUserDeferred.promise

    runs ->
      expect(form.html()).toContain 'GitHub issues will be created as @omgthatguy'

  it 'remembers the user username', ->
    spyOn(form, 'postIssue').andReturn(Q("url"))
    expect(form.username.val()).toBe ''
    form.feedbackText.val('pacman is evil')
    form.username.val("blinky@pacman.com")

    waitsForPromise ->
      form.send()

    runs ->
      form = new FeedbackFormView
      expect(form.username.val()).toBe 'blinky@pacman.com'

  describe "When there is no feedback text", ->
    it "displays an error", ->
      form.sendButton.click()
      expect(form.sendingError.find(':visible')).toBeTruthy()
      expect(form.sendingError.text().length).toBeGreaterThan 0

  describe "When there is feedback text", ->
    beforeEach ->
      form.feedbackText.text("pacman")

    it "posts feedback", ->
      spyOn(form, 'postIssue').andReturn(Q("dumbledore-url"))

      waitsForPromise ->
        form.send()

      runs ->
        expect(form.find(':contains(dumbledore-url)')).toExist()

    describe "When there is a username", ->
      beforeEach ->
        spyOn(atom, 'getGitHubAuthToken').andReturn(null)
        spyOn(form, 'requestViaPromise').andReturn(Q(html_url: "some-url"))

      it "gets rid of the @ symbol", ->
        form.username.val('@jimbob')
        waitsForPromise -> form.send()

        runs ->
          expect(form.requestViaPromise.mostRecentCall.args[0].body).toContain 'User: @jimbob'

      it "adds the @ symbol", ->
        form.username.val('  jimbob ')
        waitsForPromise -> form.send()

        runs ->
          expect(form.requestViaPromise.mostRecentCall.args[0].body).toContain 'User: @jimbob'

    describe "When the user attaches a screenshot", ->
      redDot = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='

      it "posts feedback that includes the screenshot", ->
        form.attachScreenshot.click()

        spyOn(atom.getCurrentWindow(), 'capturePage').andCallFake (cb) -> cb(redDot)
        spyOn(form, 'requestViaPromise').andReturn(Q({}))

        waitsForPromise ->
          form.send()

        runs ->
          expect(form.requestViaPromise.calls[0].args[0].body.content).toBe redDot

  describe "Issue title creation", ->
    it 'Creates legit titles', ->
      title = form.getTruncatedIssueTitle """
        McSweeney's fap ethical bicycle rights. Banjo Blue Bottle hashtag mustache roof party pork belly. Tumblr meggings raw denim deep v, umami leggings farm-to-table selvage you probably haven't heard of them.
      """
      expect(title).toEqual "McSweeney's fap ethical bicycle rights. Banjo Blue Bottle hashtag mustache roof party pork belly."

      title = form.getTruncatedIssueTitle """
        McSweeney's fap ethical bicycle rights.
        Banjo Blue Bottle hashtag mustache roof party pork belly. Tumblr meggings raw denim deep v, umami leggings farm-to-table selvage you probably haven't heard of them.
      """
      expect(title).toEqual "McSweeney's fap ethical bicycle rights."

      title = form.getTruncatedIssueTitle """
        McSweeney's fap ethical bicycle rights. Banjo Blue Bottle hashtag mustache roof party pork belly. Tumblr meggings raw denim deep v,
        umami leggings farm-to-table selvage you probably haven't heard of them.
      """
      expect(title).toEqual "McSweeney's fap ethical bicycle rights. Banjo Blue Bottle hashtag mustache roof party pork belly."

      title = form.getTruncatedIssueTitle """

        This is on another line.
      """
      expect(title).toEqual "This is on another line."
