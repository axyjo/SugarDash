SocketStream.event.on 'ready', ->
    $("script[id*='tmpl-partials-']").each ->
        id = $(this).attr "id"
        id = id.replace 'tmpl-partials-', ''
        Handlebars.registerPartial id, $(this).html()
    SugarDash.init()

