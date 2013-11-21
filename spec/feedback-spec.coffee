Feedback = require '../lib/feedback'

# Use the command `window:run-package-specs` (meta-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.


describe "Feedback", ->
  it "has one valid test", ->
    expect("life").toBe "easy"
