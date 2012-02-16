exports.actions = (req, res, ss) ->
    if(req && !req.session)
        req.session = {}

    validateInput = (input) ->
        input = input || {}
        input.uuid = input.uuid || null
        input

    getTime = (tz_obj, input) ->
        timezone = require 'timezone'
        moment = require 'moment'
        states = _.keys tz_obj
        ret = []
        now = new Date()
        now_utc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds()))

        timezone.tz.timezones require "timezone/timezones/europe"
        timezone.tz.timezones require "timezone/timezones/northamerica"
        for name, tz of tz_obj
            console.log tz
            tz_conv = timezone.tz now_utc, tz, "%H:%M:%S"
            console.log tz_conv
            data = {
                time: tz_conv
                name: name
            }
            ret.push data

        return_data {
            uuid_val: input.uuid
            data: ret
        }

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

        timeDomestic: (input) ->
            input = validateInput input
            tz = {
                "Cupertino (Pacific)": "America/Los_Angeles"
                "Utah (Mountain)": "America/Denver"
                "Texas (Central)": "America/Chicago"
                "Durham (Eastern)": "America/New_York"
            }
            getTime tz, input

        timeInternational: (input) ->
            input = validateInput input
            tz = {
                "Munich": "Europe/Berlin"
                "Paris": "Europe/Paris"
                # Montenegro and Paris are in the same timezone.
                "Montenegro": "Europe/Paris"
                "Minsk": "Europe/Minsk"
            }
            getTime tz, input

        loopback: (input) ->
            input = validateInput input
            ret = {
                uuid_val: input.uuid
                data: input
            }
            return_data ret
            res true

    }
