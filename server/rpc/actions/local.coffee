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
                    resp = {
                        uuid_val: input.uuid
                        data: JSON.parse(contents.join(''))
                    }
                    ss.publish.all 'response_'+input.uuid, resp
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
                        resp = {
                            uuid_val: input.uuid
                            data: data.responseData.feed
                        }
                        ss.publish.all 'response_'+input.uuid, resp
                        res true
                    else
                        console.error data.responseDetails
                        console.log "Error in getting data", data
                        res false
            request.end()
            console.log 'Request sent.'
    }
