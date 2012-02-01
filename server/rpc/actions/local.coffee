exports.actions = (req, res, ss) ->

    getRSSasJSON =  (url) ->
        https = require('https')
        query = {
            v: 1.0
            q: url
        }
        queryString = require('querystring').stringify query
        options = {
            host: 'ajax.googleapis.com',
            port: 443,
            path: 'ajax/services/feed/load?' + queryString,
            method: 'GET',
        }
        request = https.request options, (response) ->
            response.on "data", (chunk) ->
                console.log("got chunk:", chunk.toString())
                if(!_.isEmpty(chunk))
                    process.emit "local_success", JSON.parse(chunk.toString())

        request.end()
        console.log "Request sent."

    return {
        getWeather: (code, units) ->
            if(units != 'f' && units != 'c')
                console.error "Invalid units for getWeather."
            http = require('http')
            query = {
                p: code,
                u: units
            }
            queryString = require('querystring').stringify query
            client = http.createClient 80, 'weather.yahooapis.com'
            request = client.request 'GET', '/forecastjson?'+queryString
            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    console.log("got chunk:", chunk.toString())
                    if(!_.isEmpty(chunk))
                        res JSON.parse(chunk.toString())

        getNews: (rss_url) ->
            getRSSasJSON(rss_url)
            process.on "local_success", (data) ->
                res data
    }
