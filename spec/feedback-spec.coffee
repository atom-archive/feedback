{$, WorkspaceView} = require 'atom'
Q = require 'q'
FeedbackFormView = require '../lib/feedback-form-view'

describe "Feedback", ->
  [form] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    form = new FeedbackFormView

  it "displays the feedback form", ->
    expect(atom.workspaceView.find('.feedback')).toExist()

  it "maintains feedback values between toggles", ->
    form.feedbackText.val('who wants to live forever')
    form.trigger 'core:cancel'
    form = new FeedbackFormView
    expect(form.feedbackText.val()).toBe 'who wants to live forever'

  it "clears feedback values when feedback is sent", ->
    form.feedbackText.val("text")
    form.emailAddress.val("te@s.t")
    spyOn(form, 'sendEmail').andReturn(Q("sent"))

    waitsForPromise ->
      form.send()

    runs ->
      atom.workspaceView.trigger 'core:cancel'
      form = new FeedbackFormView
      expect(form.feedbackText.val()).toBeFalsy()

  it 'remembers the email address', ->
    spyOn(form, 'sendEmail').andReturn(Q("sent"))
    expect(form.emailAddress.val()).toBe ''
    form.feedbackText.val('pacman is evil')
    form.emailAddress.val("blinky@pacman.com")

    waitsForPromise ->
      form.send()

    runs ->
      form = new FeedbackFormView
      expect(form.emailAddress.val()).toBe 'blinky@pacman.com'

  describe "When there is no feedback text", ->
    it "displays an error", ->
      form.sendButton.click()
      expect(form.sendingError.find(':visible')).toBeTruthy()
      expect(form.sendingError.text().length).toBeGreaterThan 0

  describe "When there is feedback text", ->
    beforeEach ->
      form.feedbackText.val("pacman")
      form.emailAddress.val("pac@m.an")

    it "posts feedback", ->
      spyOn(form, 'sendEmail').andReturn(Q("sent"))

      waitsForPromise ->
        form.send()

      runs ->
        expect(form.sendEmail.calls[0].args[0].subject).toBe 'Feedback: pacman'

    describe "When the user attaches a screenshot", ->
      redDot = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='

      it "posts feedback that includes the screenshot", ->
        form.attachScreenshot.click()

        spyOn(atom.getCurrentWindow(), 'capturePage').andCallFake (cb) -> cb(redDot)
        spyOn(form, 'sendEmail').andReturn(Q('sent'))

        waitsForPromise ->
          form.send()

        runs ->
          expect(form.sendEmail.calls[0].args[0].attachments[0].contents).toBe redDot

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
