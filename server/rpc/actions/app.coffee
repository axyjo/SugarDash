exports.actions = (req, res, ss) ->
    # debug incoming requests
    console.log(req);

    return {
        square: (number) ->
            res number*number
    }
