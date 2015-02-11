module.exports =
  queue: []

  setReporter: (@reporter) ->
    for event in @queue
      @reporter.sendEvent.apply(@reporter, event)
    @queue = null

  sendEvent: (action, label, value) ->
    if @reporter
      console.log 'sendEvent', action, label
      @reporter.sendEvent('survey', action, label, value)
    else
      console.log 'queueEvent', action, label
      queue.push(['survey', action, label, value])
