exports.actions = (req, res, ss) ->
    return {
        getWeather: (input) ->
            console.log "Got request", input.uuid
            if(input.units != 'f' && input.units != 'c')
                console.error "Invalid units for getWeather."
            query = {
                p: input.weathercode,
                u: input.units
            }
            queryString = require('querystring').stringify query
            host = 'weather.yahooapis.com'
            path = '/forecastjson?'+queryString
            http = require('http')
            client = http.createClient 80, host
            request = client.request 'GET', path

            contents = []

            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    if(!_.isEmpty(chunk))
                        contents.push chunk
                response.on "end", ->
                    ss.publish.all 'response_'+input.uuid, JSON.parse(contents.join(''))
                    res true
            request.end()
            console.log 'Request sent.'

        getNews: (input) ->
            console.log "Got request", input.uuid
            query = {
                v: "1.0"
                q: input.rssurl
            }
            queryString = require('querystring').stringify query
            host = 'ajax.googleapis.com'
            path = '/ajax/services/feed/load?'+queryString
            http = require('http')
            client = http.createClient 80, host
            request = client.request 'GET', path

            contents = []

            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    if(!_.isEmpty(chunk))
                        contents.push chunk
                response.on "end", ->
                    data = JSON.parse(contents.join(''))
                    if data.responseStatus == 200
                        for entry in data.responseData.feed.entries
                            if(entry.content.length > 300)
                                entry.content = entry.contentSnippet
                        ss.publish.all 'response_'+input.uuid, data.responseData.feed
                        res true
                    else
                        console.error data.responseDetails
                        console.log "Error in getting data", data
            request.end()
            console.log 'Request sent.'
    }
