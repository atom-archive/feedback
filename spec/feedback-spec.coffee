$ = require 'jquery'

Reporter = require '../lib/reporter'
FeedbackAPI = require '../lib/feedback-api'

describe "Feedback", ->
  [feedback, workspaceElement, ajaxSuccess] = []
  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    spyOn(Reporter, 'sendEvent')
    spyOn(FeedbackAPI, 'getClientID').andReturn('1')
    spyOn($, 'ajax').andCallFake (url, {success}) ->
      ajaxSuccess = success

    waitsForPromise ->
      Promise.all [
        atom.packages.activatePackage('status-bar')
        atom.packages.activatePackage('feedback').then (pack) ->
          feedback = pack.mainModule
      ]

    waitsForPromise ->
      feedback.getStatusBar()

  describe "when the user has completed the survey", ->
    beforeEach ->
      ajaxSuccess(completed: true)

      waitsFor ->
        Reporter.sendEvent.calls.length > 0

    it "does not display the feedback status item", ->
      expect(workspaceElement.querySelector('feedback-status')).not.toExist()

  describe "when the user has not completed the survey", ->
    beforeEach ->
      ajaxSuccess(completed: false)

      waitsFor ->
        Reporter.sendEvent.calls.length > 0

    it "displays the feedback status item", ->
      expect(workspaceElement.querySelector('feedback-status')).toExist()
