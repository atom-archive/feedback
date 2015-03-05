module.exports =
  queue: []

  setReporter: (@reporter) ->
    for event in @queue
      @reporter.sendEvent.apply(@reporter, event)
    @queue = null

  sendEvent: (action, label, value) ->
    if @reporter
      @reporter.sendEvent('survey', action, label, value)
    else
      @queue.push(['survey', action, label, value])
