exports.actions = (req, res, ss) ->
    appName = 'SugarDash'
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
            process.on "sugar_success", (data) ->
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
        getNewEmployees: (count) ->
            if(_.isEmpty(count) || _.isNaN(count))
                count = 10
            request = call('get_entry_list', [process.sugar_login_id, 'Users', null, 'date_entered DESC', null, ['date_entered', 'department', 'full_name'], null, count])
            process.on "sugar_success_get_entry_list", (data) ->
                res data

        _rawCall: (func, args, params) ->
            request = _call(func, args, params)
            process.on "sugar_success_"+func, (data) ->
                res data

    }

