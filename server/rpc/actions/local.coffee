exports.actions = (req, res, ss) ->
    makeHTTPrequest = (host, path) ->
        http = require('http')
        client = http.createClient 80, host
        request = client.request 'GET', path

        contents = []

        request.on 'response', (response) ->
            response.on "data", (chunk) ->
                console.log("got chunk:", chunk.toString())
                if(!_.isEmpty(chunk))
                    contents.push chunk
            response.on "end", ->
                process.emit "local_success", JSON.parse(contents.join(''))

        request.end()
        console.log 'Request sent.'

    return {
        getWeather: (code, units) ->
            if(units != 'f' && units != 'c')
                console.error "Invalid units for getWeather."
            query = {
                p: code,
                u: units
            }
            queryString = require('querystring').stringify query
            makeHTTPrequest('weather.yahooapis.com', '/forecastjson?'+queryString)
            process.on "local_success", (data) ->
                res data

        getNews: (rss_url) ->
            query = {
                v: "1.0"
                q: rss_url
            }
            queryString = require('querystring').stringify query
            console.log queryString
            makeHTTPrequest('ajax.googleapis.com', '/ajax/services/feed/load?'+queryString)
            process.on "local_success", (data) ->
                if data.responseStatus == 200
                    res data.responseData.feed
                else
                    console.error data.responseDetails
                    console.log "Error in getting data", data
    }
