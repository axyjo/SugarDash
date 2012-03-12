SugarDash = {
    charts: {}
    loaded_charts: {}
    itemFilter: 'div.item'
    modules: ['countdowns', 'new_hires', 'sugar_satisfaction', 'jenkins', 'weather', 'current_time', 'github', 'heartbeat', 'joneses', 'soda', 'twitter']
    modulesInitialized: 0
    # 10 second flip delay.
    scrollInterval: 10*1000
    initialized: false
    init: ->
        this.container = $("#container")
        #$(window).resize()
        SugarDash.populate()
        SugarDash.initialize()
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
            SugarDash.currentItem = $("#container p")
            callback = ->
                SugarDash.modulesInitialized++
                SugarDash.nextItem = $(this.container).find(SugarDash.itemFilter).first()
                SugarDash.nextModule = SugarDash.nextItem.parents('.module')
                SugarDash.switch()

            # Load the first module content.
            SugarDash.refresh SugarDash.modules[SugarDash.modulesInitialized], false, callback

            SugarDash.initialized = true

    populate: ->
        for module in this.modules
            #console.debug "POPULATING", module
            this.refresh module, true

    refresh: (e, init = false, cb = null) ->
        if e.jquery
            module_id = e.attr('id').replace 'module_', ''
        else
            module_id = e
        #console.debug "REFRESHING", module_id
        e = $("#module_"+module_id)
        if init
            #console.debug "CREATED", module_id
            e = $ document.createElement('div')
            e.attr 'id', 'module_'+module_id
            e.data('module_id', module_id)
            e.data('module_show_count', 0)
            e.addClass 'module'
            e.appendTo("#container")
        else
            module_show_count = e.data('module_show_count')
            if(module_show_count == 0)
                callback = (module_id, e, module_data) ->
                    SugarDash.update(module_id, e, module_data)
                    cb() if cb?
                SugarDash.fetch(module_id, e, callback)
            e.data('module_show_count', module_show_count+1)

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
                $(this).data('date', $(this).html())
                $(this).html mom.fromNow()
                $(this).removeClass 'moment_datetime'
                $(this).addClass 'datetime'

            # Create any graphs required.
            e.find(".graph").each ->
                id = $(this).attr('id')
                data = module_data[id]
                data.chart.renderTo = id+"_container"
                data.chart.width = 0.9*SugarDash.container.width()
                if data.legend? and data.legend.labelFormatter?
                    data.legend.labelFormatter = new Function data.legend.labelFormatter
                SugarDash.charts[$(this).attr('id')] = data

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
                console.log "Sent request", inputs.uuid, "for", func

                ss.event.on 'response_'+inputs.uuid, (resp) ->
                    console.log "Got response", resp.uuid_val, 'for', widget_id, resp
                    module_data[widget_id] = resp.data
                    statemachine.complete widget_id

    update: (module_id, e, data) ->
        #console.debug "UPDATING", module_id
        template_id = "modules-"+module_id
        console.log("Rendering ", template_id, "with", data, "for", e)
        template = Handlebars.templates[template_id](data)
        e.html(template)

        # Create any ticking clocks required.
        e.find('span.jsclock').each ->
            data = $(this).html()
            $(this).jsclock(data)

    switch: ->
        console.debug "SWITCHING FROM", SugarDash.currentItem, "TO", SugarDash.nextItem

        trigger = ->
            # If we haven't initialized all of the modules yet, do so.
            if SugarDash.modulesInitialized < SugarDash.modules.length
                SugarDash.refresh SugarDash.modules[SugarDash.modulesInitialized]
                SugarDash.modulesInitialized++

            # Load any charts if there are some in the current item.
            hc_data = SugarDash.charts[SugarDash.currentItem.parent().attr('id')]
            if hc_data?
                SugarDash.loaded_charts[SugarDash.currentItem.parent().attr('id')] = new Highcharts.Chart hc_data

            # Update any of the dates we have in the module.
            SugarDash.currentItem.find("span.datetime").each ->
                mom = moment($(this).data('date'))
                $(this).html mom.fromNow()

            # Use the next item we've switched to as our current one. Then, reset the next item.
            SugarDash.currentItem = SugarDash.nextItem
            SugarDash.currentWidget = SugarDash.currentItem.parents('.widget')
            SugarDash.currentModule = SugarDash.currentItem.parents('.module')
            SugarDash.nextItem = []

            # If there is another item in the same widget, use that as the next item.
            if SugarDash.currentItem.next(SugarDash.itemFilter).length != 0
                SugarDash.nextItem = SugarDash.currentItem.next(SugarDash.itemFilter)
            else
                # If there is no next element in the same widget, we are at the end of the widget and need to jump to the next widget in the module.
                # We need to keep doing this until there is an item we can display.
                SugarDash.nextModule = SugarDash.currentModule
                SugarDash.nextWidget = SugarDash.currentWidget
                iterated = 0
                while SugarDash.nextItem.length == 0 and iterated < 10
                    console.debug "No item found within widget: ", SugarDash.nextWidget
                    SugarDash.nextWidget = SugarDash.currentItem.parents('.widget').next('.widget')
                    # If we have a next widget, we can use the first item in it as our nextItem.
                    if SugarDash.nextWidget.length == 1
                        SugarDash.nextItem = SugarDash.nextWidget.find(SugarDash.itemFilter)
                    # If we don't have a next widget, we're done with the current module and must move on to the next module.
                    else
                        # Until we have a widget, find the next module and get the first child widget.
                        while SugarDash.nextWidget.length == 0 and iterated < 10
                            console.debug "No widget found within module:", SugarDash.nextModule
                            SugarDash.nextModule = SugarDash.currentItem.parents('.module').next('.module')
                            # If we don't have a next module, we have to use the first module in the container.
                            # HACK: Right now, we just reload the page because for whatever reason, we get stuck in an infinite loop.
                            if SugarDash.nextModule.length == 0
                                # SugarDash.nextModule = SugarDash.container.children('.module').first()
                                window.location.reload()
                            # Refresh the next module.
                            SugarDash.refresh SugarDash.nextModule
                            # Now that we have the next module, find the first widget in it.
                            SugarDash.nextWidget = SugarDash.nextModule.children('.widget').first()
                            # MOAR HACK.
                            iterated++
                        SugarDash.nextItem = SugarDash.nextWidget.find(SugarDash.itemFilter).first()

            if SugarDash.nextItem.length > 1
                SugarDash.nextItem = SugarDash.nextItem.first()

            console.debug "Next item:", SugarDash.nextItem
            # Set the delay until the next switch.
            interval = SugarDash.scrollInterval
            interval *= 2/5 if SugarDash.currentItem.hasClass('widget_title')
            setTimeout(SugarDash.switch, interval)

        $(SugarDash.currentItem).fadeOut ->
            # Destroy the old chart, if there is one.
            if SugarDash.currentItem.find('.graph_container').first().children().length > 0
                if SugarDash.loaded_charts[SugarDash.currentItem.parent().attr('id')]?
                    SugarDash.loaded_charts[SugarDash.currentItem.parent().attr('id')].destroy()
                    SugarDash.currentItem.find('.graph_container').first().html ''

            if SugarDash.currentModule? and SugarDash.nextModule? and SugarDash.currentModule.attr('id') != SugarDash.nextModule.attr('id')
                SugarDash.currentModule.slideUp 'slow', ->
                    SugarDash.nextModule.delay(Math.random()*1500).slideDown 'slow', ->
                        SugarDash.nextItem.fadeIn ->
                            trigger()
            else if SugarDash.nextModule?
                SugarDash.nextModule.slideDown 'slow', ->
                    SugarDash.nextItem.fadeIn ->
                        trigger()
            else
                SugarDash.nextItem.fadeIn ->
                    trigger()

}
