exports.actions = (req, res, ss) ->
    appName = 'SugarDash'
    groupBy = (data, column) ->
        entry_list = {}
        for entry in data.entry_list
            val = entry.name_value_list[column].value
            if !_.isArray entry_list[val]
                entry_list[val] = []
            entry_list[val].push(entry)
        data.entry_list = entry_list

        # return data
        data

    mergeDate = (data, date_field, dateParam, valueTransform) ->
        moment = require('moment')
        epoch = moment(0)
        for entry in data.entry_list
            value = entry.name_value_list[date_field].value
            date = moment(value)
            new_value = date.diff epoch, dateParam+"s"
            entry.name_value_list[date_field+"_converted"] = {name: date_field+"_converted", value: new_value}
        # return data
        data


    getQueryString = (func, args) ->
        data = {
            method: func,
            input_type: "JSON",
            response_type: "JSON",
        }
        if(!_.isNull(args))
            data.rest_data = JSON.stringify(args)
        require('querystring').stringify data
    _call = (func, args, params) ->
        https = require('https')

        params = params || {}
        data = JSON.stringify(params)
        options = {
            host: 'sugarinternal.sugarondemand.com',
            port: 443,
            path: '/service/v4/rest.php?'+getQueryString(func, args),
            method: 'POST',
            headers: {
                'Content-Length': Buffer.byteLength(data, 'utf8'),
            },
        }
        resp = []
        request = https.request options, (response) ->
            response.on "data", (chunk) ->
                resp.push(chunk)
            response.on "end", ->
                process.emit "sugar_success_"+func, JSON.parse(resp.join(''))

        request.write data
        request.end()
        console.log("Request sent.")
    call = (func, args, params) ->
        if(!_.isEmpty(process.sugar_login_id))
            #args = args.splice(0, 0, process.sugar_login_id)
            _call func, args, params

    return {
        getServerInfo: ->
            request = call("get_server_info", '')
            process.once "sugar_success", (data) ->
                res data
        login: (username, password) ->
            loginData = [{
                user_name: username,
                password: password,
                encryption: 'PLAIN',
            }, 'SugaDash', []]
            # Only login can bypass the auth check for call.
            request = _call("login", loginData)
            process.on "sugar_success_login", (data) ->
                console.log "SESSION ID:", data.id
                process.sugar_login_id = data.id
                res data.name_value_list
        loggedIn: ->
            res !_.isEmpty(process.sugar_login_id)
        getNewEmployees: (input) ->
            if(_.isEmpty(input.count) || _.isNaN(input.count))
                input.count = 10
            #request = call('get_entry_list', [process.sugar_login_id, 'Users', null, 'date_entered DESC', null, null, null, input.count])
            request = call('get_entry_list', [process.sugar_login_id, 'Users', null, 'date_entered DESC', null, ['picture', 'date_entered', 'department', 'full_name'], null, input.count])
            process.once "sugar_success_get_entry_list", (data) ->
                ss.publish.all 'response_'+input.uuid, data
                res true
        getMilestoneDates: (input) ->
            data = [
                {date: Date.parse('Feb 29, 2012'), title: '6.4.1 GA'},
                {date: Date.parse('Mar 28, 2012'), title: '6.4.2 GA'},
                {date: Date.parse('Apr 25, 2012'), title: '6.4.3 GA'},
                {date: Date.parse('May 23, 2012'), title: '6.4.4 GA'},
                {date: Date.parse('Feb 3, 2012'), title: 'Caramel coding complete'},
                {date: Date.parse('Mar 2, 2012'), title: 'Caramel QA complete'},
                {date: Date.parse('Mar 14, 2012'), title: '6.5b1'},
                {date: Date.parse('Mar 21, 2012'), title: '6.5b2'},
                {date: Date.parse('Mar 28, 2012'), title: '6.5b3'},
                {date: Date.parse('Apr 4, 2012'), title: '6.5b4'},
                {date: Date.parse('Apr 11, 2012'), title: '6.5b5'},
                {date: Date.parse('Apr 18, 2012'), title: '6.5b6'},
                {date: Date.parse('Apr 25, 2012'), title: '6.5RC1'},
                {date: Date.parse('May 9, 2012'), title: '6.5RC2'},
                {date: Date.parse('May 23, 2012'), title: '6.5RC3'},
                {date: Date.parse('Jun 6, 2012'), title: '6.5 GA'},
            ]
            process.once

        _rawCall: (func, args, params) ->
            request = _call(func, args, params)
            process.once "sugar_success_"+func, (data) ->
                #res data
                res groupBy(mergeDate(data, 'date_entered', 'day'), 'date_entered_converted')

    }

