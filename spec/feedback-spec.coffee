{$, WorkspaceView} = require 'atom'
Q = require 'q'
FeedbackFormView = require '../lib/feedback-form-view'

describe "Feedback", ->
  [form] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    form = new FeedbackFormView
    form.email.val('mspacman@pacman.com')

  it "displays the feedback form", ->
    expect(atom.workspaceView.find('.feedback')).toExist()

  it "maintains feedback values between toggles", ->
    form.feedbackText.val('who wants to live forever')
    form.trigger 'core:cancel'
    form = new FeedbackFormView
    expect(form.feedbackText.val()).toBe 'who wants to live forever'

  it "clears feedback values when feedback is sent", ->
    form.feedbackText.val("text")
    spyOn(form, 'postFeedback').andReturn(Q(''))

    waitsForPromise ->
      form.send()

    runs ->
      atom.workspaceView.trigger 'core:cancel'
      form = new FeedbackFormView
      expect(form.feedbackText.val()).toBeFalsy()

  it 'remembers the user email', ->
    spyOn(form, 'postFeedback').andReturn(Q(''))
    expect(form.email.val()).not.toBe 'blinky@pacman.com'
    form.feedbackText.val('pacman is evil')
    form.email.val("blinky@pacman.com")

    waitsForPromise ->
      form.send()

    runs ->
      form = new FeedbackFormView
      expect(form.email.val()).toBe 'blinky@pacman.com'

  describe "When there is no feedback text", ->
    it "displays an error", ->
      form.sendButton.click()
      expect(form.sendingError.find(':visible')).toBeTruthy()
      expect(form.sendingError.text().length).toBeGreaterThan 0

  describe "When there is feedback text", ->
    beforeEach ->
      form.feedbackText.val("pacman")

    it "posts feedback", ->
      spyOn(form, 'postFeedback').andReturn(Q(''))

      waitsForPromise ->
        form.send()

    describe "When there is no email", ->
      beforeEach ->
        spyOn(atom, 'getGitHubAuthToken').andReturn(null)
        spyOn(form, 'requestViaPromise').andReturn(Q(html_url: "some-url"))

      it "shows an error", ->
        form.email.val('bad')
        waitsForPromise ->
          form.send()

        runs ->
          expect(form.sendingError.text()).toBe "'bad' is not a valid email address"
