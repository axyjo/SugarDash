exports.actions = (req, res, ss) ->
    if(req && !req.session)
        req.session = {}

    validateInput = (input) ->
        input = input || {}
        input.uuid = input.uuid || null
        input

    return_data = (data) ->
        if _.isObject(data) and _.isString(data.uuid_val)
            ss.publish.all 'response_'+data.uuid_val, data
            res true
        else
            res data
    return {
        refresh: () ->
            ss.publish.all 'refresh', 'refresh'
            res true
        square: (number) ->
            res number*number
        time: (input) ->
            input = validateInput input
            if input.tz?
                host = 'json-time.appspot.com'
                path = '/time.json?tz='+input.tz
                http = require('http')
                client = http.createClient 80, host
                request = client.request 'GET', path

                contents = []

                request.on 'response', (response) ->
                    response.on "data", (chunk) ->
                        if(!_.isEmpty(chunk))
                            contents.push chunk
                    response.on "end", ->
                        moment = require('moment')
                        resp = JSON.parse(contents.join(''))
                        date = moment().hours(resp.hour).minutes(resp.minute).seconds(resp.second)
                        data = {
                            data: {time: date.format('HH:mm:ss')}
                            uuid_val: input.uuid
                        }
                        return_data data
                request.end()
                console.log 'Request sent.'

        loopback: (input) ->
            input = validateInput input
            ret = {
                uuid_val: input.uuid
                data: input
            }
            return_data ret
            res true

    }
