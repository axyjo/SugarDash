exports.actions = (req, res, ss) ->

    since = (q) ->
        if not process.twitter_query?
            process.twitter_query = {}
        (process.twitter_query[q] || null)

    return_data = (data) ->
        if _.isObject(data) and _.isString(data.uuid_val)
            ss.publish.all 'response_'+data.uuid_val, data
            res true
        else
            res data
    call = (input, cb) ->
        console.log "Got request", input.uuid
        https = require('https')

        data = data || {}
        data = JSON.stringify data
        console.log "Sending", data

        options = {
            host: 'api.github.com'
            port: 443
            path: input.path + '?' + process.github_token
            method: 'GET'
            headers: {
                'Content-Length': Buffer.byteLength(data, 'utf8')
            }
        }
        resp = []
        request = https.request options, (response) ->
            response.on "data", (chunk) ->
                resp.push(chunk)
            response.on "end", ->
                try
                    response_body = JSON.parse resp.join('')
                    cb response_body
                catch error
                    console.log "Non JSON response:", resp.join('')
                    console.log "Error:", error

        request.write data
        request.end()
        console.log("Request sent.")

    client_id = "ef7345be94c480cff2c2"

    client_secret = "80c48e58805c349e3793f2344fa50e3f562b6a42"


    return {
        pulls: (input) ->
            # OAuth path:
            # https://github.com/login/oauth/authorize?client_id=ef7345be94c480cff2c2
            input = input || {}
            input.path = "/repos/" + input.repo + "/pulls"
            cb = (result) ->
                ret = {
                    uuid_val: input.uuid
                    data: result.splice 0, input.limit-1 || 9
                }
                return_data ret
            call input, cb
        getOAuthPath: ->
            opts = {
                client_id: client_id
                scope: 'repo'
            }
            res "https://github.com/login/oauth/authorize?" +  require('querystring').stringify opts

        getOAuthAccessToken: (code) ->
            https = require('https')

            data = require('querystring').stringify {
                code: code
                client_id: client_id
                client_secret: client_secret
            }

            options = {
                host: 'github.com'
                port: 443
                path: '/login/oauth/access_token'
                method: 'POST'
                headers: {
                    'Content-Length': Buffer.byteLength(data, 'utf8')
                }
            }
            resp = []
            request = https.request options, (response) ->
                response.on "data", (chunk) ->
                    resp.push(chunk)
                response.on "end", ->
                    try
                        process.github_token = resp.join('')
                        console.log "GitHub auth: ", process.github_token
                        res true
                    catch error
                        console.log "Invalid response:", resp.join('')
                        console.log "Error:", error

            request.write data
            request.end()
    }
