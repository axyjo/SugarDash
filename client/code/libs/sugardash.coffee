SugarDash = {
    panelFilter: 'div.panel'
    #panels: ['new_hires', 'twitterscope', 'twitterscope2', 'joneses_sprintwise']
    panels: ['local_weather', 'local_news', 'twitterscope']
    init: ->
        this.container = $("#container")
        #$(window).resize()
        this.populate()
        setInterval(this.switch, 10*1000)
        $("#container p").remove()
    generateUUID: ->
        s = [];
        hexDigits = "0123456789abcdef";
        for i in [0..35]
            s[i] = hexDigits.substr Math.floor(Math.random() * 0x10), 1
        s[14] = "4"  # bits 12-15 of the time_hi_and_version field to 0010
        s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1)  # bits 6-7 of the clock_seq_hi_and_reserved to 01
        s[8] = s[13] = s[18] = s[23] = "-"
        s.join("")
    populate: ->
        console.log Handlebars.templates
        for panel in this.panels
            this.refresh(panel)
        SugarDash.current = $(this.container).children(SugarDash.panelFilter).first()
        SugarDash.next = SugarDash.current.next()
        SugarDash.current.fadeIn()
    refresh: (panel_id) ->
        e = $("#panel_"+panel_id)
        if(e.length == 0)
            console.debug "created panel", panel_id, e
            e = $ document.createElement('div')
            e.attr 'id', 'panel_'+panel_id
            e.data('panel_id', panel_id)
            e.data('panel_show_count', 0)
            e.addClass 'panel'
            e.appendTo("#container")
        panel_show_count = e.data('panel_show_count')
        if(panel_show_count % 30 == 0)
            SugarDash.fetch(panel_id, e, SugarDash.update)
        e.data('panel_show_count', panel_show_count + 1)
        $("footer").html('Last updated: ' + moment($("footer").data('last_updated')).fromNow())
    fetch: (panel_id, e, cb) ->
        console.log "fetching", panel_id
        template_id = "panels-"+panel_id
        template = Handlebars.templates[template_id] {}
        panel_data = {}
        states = []
        $(template).each ->
            if $(this).is('div')
                $(this).find('.widget').each ->
                    widget_id = $(this).attr "id"
                    states.push widget_id
        console.log states
        callback = ->
            console.debug "sent", panel_data, "to", panel_id
            cb panel_id, e, panel_data
            $("footer").data("last_updated", Date.now())
            #update any moment_datetimes
            e.find("span.moment_datetime").each ->
                mom = moment($(this).html())
                $(this).html mom.fromNow()
                $(this).removeClass 'moment_datetime'
                $(this).addClass 'datetime'
            e.find(".graph").each ->
                data = panel_data[$(this).attr('id')]
                data.chart.renderTo = $(this).attr('id')
                chart = new Highcharts.Chart data
        statemachine = new State(states, callback, this)
        $(template).each ->
            if $(this).is('div')
                $(this).find('.widget').each ->
                    widget_id = $(this).attr "id"
                    console.log widget_id
                    # Default values:
                    func = 'sugar.loggedIn'
                    inputs = {}

                    func = $(this).data "func"
                    inputs = $(this).data()
                    inputs.uuid = SugarDash.generateUUID()
                    ss.rpc func, inputs
                    console.log "Sent request", inputs.uuid, "to", func

                    ss.event.on 'response_'+inputs.uuid, (resp) ->
                        console.log "Got response", resp.uuid_val, 'for', widget_id, resp
                        panel_data[widget_id] = resp.data
                        statemachine.complete widget_id

    update: (panel_id, e, data) ->
        template_id = "panels-"+panel_id
        template = Handlebars.templates[template_id](data)
        e.html(template)

    switch: ->
        $(SugarDash.current).fadeOut()
        SugarDash.next.fadeIn()
        SugarDash.current = SugarDash.next
        SugarDash.next = $(SugarDash.current).next(SugarDash.panelFilter)
        if SugarDash.next.length == 0
            SugarDash.next = $(SugarDash.container.children(SugarDash.panelFilter)).first()
        SugarDash.refresh(SugarDash.next.data('panel_id'))
}
