{$, WorkspaceView} = require 'atom'
Q = require 'q'
FeedbackFormView = require '../lib/feedback-form-view'

describe "Feedback", ->
  form = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.packages.activatePackage('feedback')
    form = new FeedbackFormView
    spyOn(form, 'postIssue').andReturn(Q("dumbledore-url"))


  it "displays the feedback form", ->
    expect(atom.workspaceView.find('.feedback')).toExist()

  it 'remembers the user email', ->
    expect(form.email.text()).toBe ''
    form.feedbackText.text('pacman is evil')
    form.email.text("blinky@pacman.com")

    waitsForPromise ->
      form.send()

    runs ->
      form = new FeedbackFormView
      expect(form.email.text()).toBe 'blinky@pacman.com'


  describe "When there is no feedback text", ->
    it "displays an error", ->
      form.sendButton.click()
      expect(form.sendingError.find(':visible')).toBeTruthy()
      expect(form.sendingError.text().length).toBeGreaterThan 0

  describe "When there is feedback text", ->
    beforeEach ->
      form.feedbackText.text("pacman")

    it "posts feedback", ->
      waitsForPromise ->
        form.send()

      runs ->
        expect(form.find(':contains(dumbledore-url)')).toExist()

    describe "When the user attaches a screenshot", ->
      redDot = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='
      beforeEach ->
        spyOn(atom.getCurrentWindow(), 'capturePage').andCallFake (cb) -> cb(redDot)
        spyOn(form, 'requestViaPromise').andCallThrough()

      it "posts feedback that includes the screenshot", ->
        waitsForPromise ->
          form.attachScreenshot.click()
          form.updateScreenshot()

        waitsForPromise ->
          form.send()

        runs ->
          expect(form.find(':contains(dumbledore-url)')).toExist()
          expect(form.requestViaPromise.calls[0].args[0].body.content).toBe redDot
