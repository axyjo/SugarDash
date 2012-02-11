exports.actions = (req, res, ss) ->
    return {
        start: ->
            host = 'pipes.yahoo.com'
            path = '/pipes/pipe.run?_id=e3589132276a3fffd05a3832b1109c23&_render=json'
            http = require('http')
            client = http.createClient 80, host
            request = client.request 'GET', path

            contents = []

            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    if(!_.isEmpty(chunk))
                        contents.push chunk
                response.on "end", ->
                    resp = JSON.parse(contents.join(''))
                    res resp.value.items
            request.end()
            console.log 'Request sent.'
    }
