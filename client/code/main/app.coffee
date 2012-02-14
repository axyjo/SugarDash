SocketStream.event.on 'ready', ->

    # Register Handlebars partials.
    for key, value of Handlebars.templates
        split = key.split('-')
        folder = split[0]
        if folder is "partials"
            Handlebars.registerPartial split[1], Handlebars.templates[key]

    # Register Handlebars row-dividers helper.
    Handlebars.registerHelper "divide", (array, options) ->
        if array? and array.length > 0
            buffer = '<div class="row-fluid">'
            for row, i in array
                if i % 3 == 0 and i != 0
                    buffer += '</div><div class="row-fluid">'
                buffer += options.fn row
            buffer + '</div>'

    ss.event.on 'refresh', ->
        window.location.reload()

    # Resize handler
    resizeFunc = ->
        console.log "Resize"
        $("#container").height ($(window).height() - $("#ticker").outerHeight())
    $(document).ready ->
        $(window).resize resizeFunc
        resizeFunc.call()

        # Refresh every 30 mins - 1 hr.
        refresh_time = (Math.random() * 0.5 + 0.5) * (60 * 60 * 100)
        setTimeout ->
            window.location.reload()
        , refresh_time

    SugarDash.init()

