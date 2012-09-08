# Register Handlebars row-dividers helper.
Handlebars.registerHelper "divide", (array, options) ->
    if array? and array.length > 0
        buffer = '<div class="row-fluid">'
        for row, i in array
            if i % 3 == 0 and i != 0
                buffer += '</div><div class="row-fluid">'
            buffer += options.fn row
        return buffer + '</div>'

Handlebars.registerHelper "debug", (val) ->
    console.log "Context:", this
    console.log "Value:", val if val? and val isnt {}

Handlebars.registerHelper "key_value", (obj, fn) ->
    buffer = ""
    for key, val of obj
        buffer += fn {key: key, value: val}

    return buffer

# Register Handlebars partials.
for key, value of Handlebars.templates
    split = key.split('-')
    folder = split[0]
    if folder is "partials"
        Handlebars.registerPartial split[1], Handlebars.templates[key]

ss.event.on 'refresh', ->
    window.location.reload()

# Resize handler
resizeFunc = ->
    $("#container").height ($(window).height() - $("#ticker").outerHeight())


$(window).resize resizeFunc
resizeFunc.call()

SugarDash.init()


