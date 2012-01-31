exports.actions = (req, res, ss) ->
    # debug incoming requests
    console.log(req);
    if(req && !req.session)
        req.session = {}
    return {
        square: (number) ->
            res number*number
    }
