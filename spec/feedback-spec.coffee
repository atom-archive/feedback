$ = require 'jquery'

Reporter = require '../lib/reporter'
FeedbackAPI = require '../lib/feedback-api'

describe "Feedback", ->
  [feedback, workspaceElement, ajaxSuccess] = []
  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    spyOn(Reporter, 'sendEvent')
    spyOn(FeedbackAPI, 'getClientID').andReturn('someuser')
    spyOn(FeedbackAPI, 'fetchSurveyMetadata').andReturn new Promise (resolve) ->
      resolve({display_seed: 'none', display_percent: 5})
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
      expect(Reporter.sendEvent).toHaveBeenCalledWith('already-finished-survey-activate')

  describe "when the user has not completed the survey", ->
    beforeEach ->
      ajaxSuccess(completed: false)

      waitsFor ->
        Reporter.sendEvent.calls.length > 0

    it "displays the feedback status item", ->
      expect(workspaceElement.querySelector('feedback-status')).toExist()
      expect(Reporter.sendEvent).toHaveBeenCalledWith('did-show-status-bar-link')

    describe "when the user opens the dialog and clicks cancel", ->
      it "displays the modal, and can click ", ->
        workspaceElement.querySelector('feedback-status a').dispatchEvent(new Event('click'))
        expect(workspaceElement.querySelector('feedback-modal')).toBeVisible()

        expect(workspaceElement.querySelector('feedback-modal .btn-primary').href).toContain feedback.feedbackSource
        expect(workspaceElement.querySelector('feedback-modal .btn-primary').href).toContain 'someuser'

        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-show-status-bar-link')
        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-click-status-bar-link')
        expect(Reporter.sendEvent).not.toHaveBeenCalledWith(feedback.feedbackSource, 'did-click-modal-cancel')

        workspaceElement.querySelector('feedback-modal .btn-cancel').dispatchEvent(new Event('click'))

        expect(workspaceElement.querySelector('feedback-modal')).not.toBeVisible()
        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-click-modal-cancel')

    describe "when the user opens the dialog and starts the ", ->
      beforeEach ->
        ajaxSuccess = null
        FeedbackAPI.PollInterval = 100
        expect(workspaceElement.querySelector('feedback-status')).toBeVisible()

      it "displays the modal, and can click ", ->
        workspaceElement.querySelector('feedback-status a').dispatchEvent(new Event('click'))

        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-show-status-bar-link')
        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-click-status-bar-link')
        expect(Reporter.sendEvent).not.toHaveBeenCalledWith(feedback.feedbackSource, 'did-click-modal-cancel')

        workspaceElement.querySelector('feedback-modal .btn-primary').setAttribute('href', '#')
        workspaceElement.querySelector('feedback-modal .btn-primary').dispatchEvent(new Event('click'))
        expect(Reporter.sendEvent).toHaveBeenCalledWith('did-click-modal-cta')

        expect(workspaceElement.querySelector('feedback-modal')).not.toBeVisible()
        expect(workspaceElement.querySelector('feedback-status')).toBeVisible()

        # now it will poll the atom.io api to see if the user has
        waits 0
        runs ->
          advanceClock(FeedbackAPI.PollInterval)
          ajaxSuccess(completed: false)
          ajaxSuccess = null
          expect(workspaceElement.querySelector('feedback-status')).toBeVisible()

        waits 0
        runs ->
          advanceClock(FeedbackAPI.PollInterval)
          ajaxSuccess(completed: false)
          ajaxSuccess = null
          expect(workspaceElement.querySelector('feedback-status')).toBeVisible()

        waits 0
        runs ->
          advanceClock(FeedbackAPI.PollInterval)
          ajaxSuccess(completed: true)
          ajaxSuccess = null

        waits 0
        runs ->
          advanceClock(FeedbackAPI.PollInterval)
          expect(ajaxSuccess).toBe null
          expect(workspaceElement.querySelector('feedback-status')).not.toBeVisible()
          expect(Reporter.sendEvent).toHaveBeenCalledWith('did-finish-survey')
