Ticker = {
    ticker_items: []
    current_index: 0
    init: ->
        ss.rpc 'ticker.start', (data) ->
            for news in data
                if news?
                    Ticker.ticker_items.push news.title
            console.log "Ticker is good to go."
            setTimeout Ticker.switch, 3500

        ss.event.on "ticker", (data) ->
            for news in data
                if news? and _.isObject news
                    @ticker_items.push

    switch: ->
        $("#ticker p").animate { opacity: 'toggle', height: 'toggle' }, ->
            $("#ticker p").html Ticker.ticker_items[Ticker.current_index]
            Ticker.current_index++
            Ticker.current_index = 0 if Ticker.current_index >= Ticker.ticker_items.length
            $("#ticker p").animate { opacity: 'toggle', height: 'toggle' }, ->
                clearTimeout(Ticker.timeout) if Ticker.timeout?
                Ticker.timeout = setTimeout Ticker.switch, 7500
                $("#container").height ($(window).height() - $("#ticker").outerHeight())

}

SocketStream.event.on 'ready', ->
    Ticker.init()
