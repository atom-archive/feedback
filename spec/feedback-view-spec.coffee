FeedbackView = require '../lib/feedback-view'
{atom.rootView} = require 'atom'

describe "FeedbackView", ->
  feedback = null

  beforeEach ->
    window.atom.rootView = new atom.rootView
    feedback = atom.activatePackage('feedback', immediate: true)

  describe "when the feedback:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.rootView.find('.feedback')).not.toExist()
      atom.rootView.trigger 'feedback:toggle'
      expect(atom.rootView.find('.feedback')).toExist()
      atom.rootView.trigger 'feedback:toggle'
      expect(atom.rootView.find('.feedback')).not.toExist()
