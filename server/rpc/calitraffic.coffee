exports.actions = (req, res, ss) ->

    return_data = (data) ->
        if _.isObject(data) and _.isString(data.uuid_val)
            ss.publish.all 'response_'+data.uuid_val, data
            res true
        else
            res data

    validateInput = (input) ->
        input = input || {}
        input.uuid = input.uuid || null
        input

    return {
        getTraffic: (input) ->
            input = validateInput input
            console.log "Got request", input.uuid
            host = 'pipes.yahoo.com'
            path = '/pipes/pipe.run?_id=ba84ca009604eb290436cca19832586e&_render=json'
            http = require('http')
            client = http.createClient 80, host
            request = client.request 'GET', path

            contents = []

            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    if(!_.isEmpty(chunk))
                        contents.push chunk
                response.on "end", ->
                    data = JSON.parse contents.join ''
                    data = data.value.items[0]["Center"]
                    if input.center?
                        for d in data
                            if d["ID"] == input.center
                                data = d["Dispatch"]["Log"]
                                break
                    if !_.isArray data
                        data = [data]
                    resp = {
                        uuid_val: input.uuid
                        data: data
                    }
                    return_data resp
            request.end()
            console.log 'Request sent.'
    }
