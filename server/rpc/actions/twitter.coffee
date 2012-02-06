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

    return {
        search: (input) ->
            console.log "Got request", input.uuid
            query = {
                q: input.q
                since_id: since input.q
            }
            queryString = require('querystring').stringify query
            host = 'search.twitter.com'
            path = '/search.json?'+queryString
            http = require('http')
            client = http.createClient 80, host
            request = client.request 'GET', path

            contents = []

            request.on 'response', (response) ->
                response.on "data", (chunk) ->
                    if(!_.isEmpty(chunk))
                        contents.push chunk
                response.on "end", ->
                    d = JSON.parse(contents.join(''))

                    if not process.twitter_results?
                        process.twitter_results = {}
                    if not process.twitter_results[input.q]?
                        process.twitter_results[input.q] = []
                    process.twitter_results[input.q] = d.results.concat process.twitter_results[input.q]
                    process.twitter_results[input.q] = process.twitter_results[input.q].slice 0, 19

                    resp = {
                        uuid_val: input.uuid
                        data: process.twitter_results[input.q].slice 0, input.limit || 10
                    }

                    process.twitter_query[input.q] = d.max_id_str
                    return_data resp
            request.end()
            console.log 'Request sent.'
    }
