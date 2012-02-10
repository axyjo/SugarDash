module.exports = {
    respond: (input, data) ->
        if _.isObject(data)
            ss.publish.all 'response_'+input.uuid, data

}
