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
            path: input.path + '?'
            method: 'GET'
            headers: {
                'Content-Length': Buffer.byteLength(data, 'utf8')
                'Authorization': 'Basic ' + new Buffer(process.env.GH_USER + ':' + process.env.GH_PASS, 'base64')
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
            input = input || {}
            input.path = "/repos/" + input.repo + "/pulls"
            cb = (result) ->
                ret = {
                    uuid_val: input.uuid
                    data: result.splice 0, input.limit-1 || 9
                }
                return_data ret
            call input, cb
    }
