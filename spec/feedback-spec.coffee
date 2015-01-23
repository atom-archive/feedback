describe "Feedback", ->
  [workspaceElement] = []
  beforeEach ->
    waitsForPromise ->
      workspaceElement = atom.views.getView(atom.workspace)
      atom.packages.activatePackage('feedback')

  it "displays the feedback status item", ->
    waitsForPromise ->
      atom.packages.activatePackage('status-bar')
    runs ->
      expect(workspaceElement.querySelector('feedback-status')).toExist()
