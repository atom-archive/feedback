$ = require 'jquery'

SurveyURL = 'https://atom.io/survey'

module.exports =
  PollInterval: 10000

  getClientID: ->
    localStorage.getItem('metrics.userId')

  getSurveyURL: (source) ->
    "#{SurveyURL}/#{source}/#{@getClientID()}"

  fetchDidCompleteFeedback: (source) ->
    new Promise (resolve) =>
      url = "https://atom.io/api/feedback/#{source}/#{@getClientID()}"
      $.ajax url,
        accept: 'application/json'
        contentType: "application/json"
        success: (data) -> resolve(data.completed)

  detectDidCompleteFeedback: (source) ->
    detectCompleted = (callback) =>
      @cancelDidCompleteFeedbackDetection()
      @detectionTimeout = setTimeout =>
        @fetchDidCompleteFeedback(source).then (didCompleteFeedback) ->
          if didCompleteFeedback
            callback(true)
          else
            detectCompleted(callback)
      , @PollInterval

    new Promise (resolve) =>
      detectCompleted (completed) -> resolve(completed)

  cancelDidCompleteFeedbackDetection: ->
    clearTimeout(@detectionTimeout)
    @detectionTimeout = null
