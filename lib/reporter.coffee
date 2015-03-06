module.exports =
  queue: []
  source: 'survey-2015-1'

  setReporter: (@reporter) ->
    for event in @queue
      @reporter.sendEvent.apply(@reporter, event)
    @queue = null

  sendEvent: (action, label, value) ->
    if @reporter
      @reporter.sendEvent(@source, action, label, value)
    else
      @queue.push([@source, action, label, value])
