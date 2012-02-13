SugarDash = {
    charts: {}
    loaded_charts: {}
    itemFilter: 'div.item'
    modules: ['countdowns', 'weather', 'github', 'joneses', 'soda', 'twitter']
    # 10 second flip delay.
    scrollInterval: 10*1000
    initialized: false
    init: ->
        this.container = $("#container")
        #$(window).resize()
        this.populate()
    generateUUID: ->
        s = [];
        hexDigits = "0123456789abcdef";
        for i in [0..35]
            s[i] = hexDigits.substr Math.floor(Math.random() * 0x10), 1
        s[14] = "4"  # bits 12-15 of the time_hi_and_version field to 0010
        s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1)  # bits 6-7 of the clock_seq_hi_and_reserved to 01
        s[8] = s[13] = s[18] = s[23] = "-"
        s.join("")
    initialize: ->
        if !SugarDash.initialized
            SugarDash.current = $("#container p")
            SugarDash.next = $(this.container).find(SugarDash.itemFilter).first()
            SugarDash.newModule = SugarDash.next.parents('.module')
            SugarDash.switch()
            SugarDash.initialized = true

    populate: ->
        for module in this.modules
            #console.debug "POPULATING", module
            this.refresh(module)

    refresh: (module_id) ->
        #console.debug "REFRESHING", module_id
        e = $("#module_"+module_id)
        if(e.length == 0)
            #console.debug "CREATED", module_id
            e = $ document.createElement('div')
            e.attr 'id', 'module_'+module_id
            e.data('module_id', module_id)
            e.data('module_show_count', 0)
            e.addClass 'module'
            e.appendTo("#container")
        module_show_count = e.data('module_show_count')
        if(module_show_count == 0)
            SugarDash.fetch(module_id, e, SugarDash.update)
        e.data('module_show_count', module_show_count+1)
        $("footer").html('Last updated: ' + moment($("footer").data('last_updated')).fromNow())

    fetch: (module_id, e, cb) ->
        #console.debug "FETCHING", module_id
        template_id = "modules-"+module_id
        template = Handlebars.templates[template_id] {}
        module_data = {}
        states = []
        $(template).each ->
            if $(this).is('.widget')
                $(this).data('module_id', module_id)
                widget_id = $(this).attr "id"
                console.log "FOUND WIDGET:", widget_id
                states.push widget_id
        callback = ->
            #console.debug "sent", module_data, "to", module_id
            cb module_id, e, module_data
            $("footer").data("last_updated", Date.now())
            #update any moment_datetimes
            e.find("span.moment_datetime").each ->
                mom = moment($(this).html())
                $(this).html mom.fromNow()
                $(this).removeClass 'moment_datetime'
                $(this).addClass 'datetime'
            e.find(".graph").each ->
                id = $(this).attr('id')
                data = module_data[id]
                data.chart.renderTo = id+"_container"
                data.chart.width = 0.9*SugarDash.container.width()
                if data.legend? and data.legend.labelFormatter?
                    data.legend.labelFormatter = new Function data.legend.labelFormatter
                SugarDash.charts[$(this).attr('id')] = data
            SugarDash.initialize()
        statemachine = new State(states, callback, this)
        $(template).each ->
            if $(this).is('.widget')
                widget_id = $(this).attr "id"
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
                    module_data[widget_id] = resp.data
                    statemachine.complete widget_id

    update: (module_id, e, data) ->
        #console.debug "UPDATING", module_id
        template_id = "modules-"+module_id
        template = Handlebars.templates[template_id](data)
        e.html(template)

    switch: ->
        #console.debug "SWITCHING FROM", SugarDash.current, "TO", SugarDash.next

        setVars = ->
            SugarDash.current = SugarDash.next
            SugarDash.next = $(SugarDash.current).next(SugarDash.itemFilter)
            # Debug infinite loop.
            recurse = 0
            while SugarDash.next.length == 0 && recurse < 5
                recurse++
                console.log "LAST CHILD:", SugarDash.current.parent().find('div.item:last')
                if SugarDash.current.is SugarDash.current.parent().find('div.item:last')
                    #console.debug "LAST CHILD IN THIS WIDGET"
                    if SugarDash.current.parents('.widget').is SugarDash.current.parents('.module').find('div.widget:last')
                        #console.debug "LAST CHILD IN THIS MODULE"
                        SugarDash.oldModule = SugarDash.current.parents('.module')
                        SugarDash.newModule = SugarDash.oldModule.next('.module')
                        if SugarDash.newModule.length == 0
                            SugarDash.newModule = SugarDash.oldModule.siblings('.module').first()
                        #console.debug "Next Module:", SugarDash.newModule
                        SugarDash.next = SugarDash.newModule.find(SugarDash.itemFilter).first()
                    else
                        SugarDash.next = SugarDash.current.parents('.widget').next().find(SugarDash.itemFilter).first()
            #console.debug "NEXT", SugarDash.next
            SugarDash.refresh(SugarDash.next.parents('.module').data('module_id'))

            # Load any charts if there are some.
            hc_data = SugarDash.charts[SugarDash.current.parent().attr('id')]
            if hc_data?
                SugarDash.loaded_charts[SugarDash.current.parent().attr('id')] = new Highcharts.Chart hc_data

            setTimeout(SugarDash.switch, SugarDash.scrollInterval)

        $(SugarDash.current).fadeOut ->
            # Destroy the old chart, if there is one.
            if SugarDash.current.find('.graph_container').length > 0
                if SugarDash.loaded_charts[SugarDash.current.parent().attr('id')]?
                    SugarDash.loaded_charts[SugarDash.current.parent().attr('id')].destroy()
            if SugarDash.oldModule? and SugarDash.newModule?
                SugarDash.oldModule.slideUp 'slow', ->
                    SugarDash.newModule.delay(Math.random()*1500).slideDown 'slow', ->
                        SugarDash.next.fadeIn ->
                            setVars()
            else if SugarDash.newModule?
                SugarDash.newModule.slideDown 'slow', ->
                    SugarDash.next.fadeIn ->
                        setVars()
            else
                SugarDash.next.fadeIn ->
                    setVars()




}
