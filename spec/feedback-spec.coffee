{$, RootView} = require 'atom'
Q = require 'q'
FeedbackFormView = require '../lib/feedback-form-view'

describe "Feedback", ->
  form = null

  beforeEach ->
    atom.rootView = new RootView
    atom.packages.activatePackage('feedback')
    form = new FeedbackFormView

  it "displays the feedback form", ->
    expect(atom.rootView.find('.feedback')).toExist()

  describe "When there is no feedback text", ->
    it "displays an error", ->
      form.sendButton.click()
      expect(form.sendingError.find(':visible')).toBeTruthy()
      expect(form.sendingError.text().length).toBeGreaterThan 0

  describe "When there is feedback text", ->
    beforeEach ->
      form.textarea.text("pacman")

    it "posts feedback", ->
      spyOn(form, 'createIssue').andReturn(Q("dumbledore-url"))

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
        spyOn(form, 'createIssue').andReturn(Q("dumbledore-url"))

        waitsForPromise ->
          form.attachScreenshot.click()
          form.updateScreenshot()

        waitsForPromise ->
          form.send()

        runs ->
          expect(form.find(':contains(dumbledore-url)')).toExist()
          expect(form.requestViaPromise.calls[0].args[0].body.content).toBe redDot
