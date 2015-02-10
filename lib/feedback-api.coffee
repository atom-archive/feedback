$ = require 'jquery'

module.exports =
  fetchDidCompleteFeedback: (source) ->
    new Promise (resolve) =>
      url = "https://atom.io/api/feedback/#{source}/#{@getClientID()}"
      $.ajax url,
        accept: 'application/json'
        contentType: "application/json"
        success: (data) -> resolve(data.completed)

  getClientID: ->
    localStorage.getItem('metrics.userId')
