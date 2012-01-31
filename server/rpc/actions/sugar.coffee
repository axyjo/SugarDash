exports.actions = (req, res, ss) ->
    getQueryString = (func, args) ->
        console.log("Getting query string");
        data = {
            method: func,
            input_type: "JSON",
            response_type: "JSON",
        }
        if(!_.isNull(args))
            data.rest_data = JSON.stringify(args)
        console.log "stringified."
        require('querystring').stringify data
    call = (func, args, params) ->
        https = require('https')
        console.log("Making a call to", func, "with args:", args);

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

        request = https.request options, (response) ->
            response.on "data", (chunk) ->
                console.log("got chunk:", chunk.toString())
                if(!_.isEmpty(chunk))
                    process.emit "sugar_success", JSON.parse(chunk.toString())

        request.write(data)
        request.end()
        console.log("Request sent.")

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
            request = call("login", loginData)
            process.on "sugar_success", (data) ->
                res data
    }

