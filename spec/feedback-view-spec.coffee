FeedbackView = require '../lib/feedback-view'
{RootView} = require 'atom'

describe "FeedbackView", ->
  feedback = null

  beforeEach ->
    window.rootView = new RootView
    feedback = atom.activatePackage('feedback', immediate: true)

  describe "when the feedback:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(rootView.find('.feedback')).not.toExist()
      rootView.trigger 'feedback:toggle'
      expect(rootView.find('.feedback')).toExist()
      rootView.trigger 'feedback:toggle'
      expect(rootView.find('.feedback')).not.toExist()
