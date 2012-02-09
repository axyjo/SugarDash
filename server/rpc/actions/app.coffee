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
        loopback: (input) ->
            input = validateInput input
            ret = {
                uuid_val: input.uuid
                data: input
            }
            return_data ret
            res true

    }
