SocketStream.event.on 'ready', ->
    $(window).resize SugarDash.maintainAspectRatio
    SugarDash.init()

