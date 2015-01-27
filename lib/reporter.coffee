$ = require 'jquery'
querystring = require 'querystring'

module.exports =
  sendEvent: (name, label, value) ->
    params =
      t: 'event'
      ec: 'survey'
      ea: name
      el: label
      ev: value
    @send(params)

  send: (params) ->
    $.extend(params, @defaultParams())
    @request
      type: 'POST'
      url: "https://www.google-analytics.com/collect?#{querystring.stringify(params)}"

  request: (options) ->
    $.ajax(options) if navigator.onLine

  defaultParams: ->
    # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
    {
      v: 1
      tid: "UA-3769691-33"
      cid: localStorage.getItem('metrics.userId')
      an: 'atom'
      av: atom.getVersion()
      sr: "#{screen.width}x#{screen.height}"
    }
