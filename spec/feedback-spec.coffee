{$, WorkspaceView} = require 'atom'
Q = require 'q'

describe "Feedback", ->
  [form] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    waitsForPromise ->
      atom.packages.activatePackage('feedback')

  it "displays the feedback view", ->
    expect(atom.workspaceView.find('.feedback')).not.toExist()
    atom.workspaceView.trigger('feedback:show')
    expect(atom.workspaceView.find('.feedback')).toExist()
