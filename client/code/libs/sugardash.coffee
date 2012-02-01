SugarDash = {
    panelFilter: 'div.panel'
    panels: ['new_hires', 'birthdays', 'local_news']
    init: ->
        this.container = $("#container")
        #$(window).resize()
        this.populate()
        setInterval(this.switch, 5*1000)
        $("#container p").fadeOut('fast').remove()
    maintainAspectRatio: ->
        container = $(this.container)
        width = $(window).width()
        height = $(window).height()
        if(width/height > 16/9)
            container.width 16/9*height
            container.height 9/16*container.width()
        else
            container.height 9/16*height
            container.width 16/9*container.height()
    populate: ->
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
        if(panel_show_count % 20 == 0)
            template_id = "#tmpl-panels-"+panel_id
            template = Handlebars.compile($(template_id).html())
            output = template({
            })
            e.html(output)
        else
            e.data('panel_show_count', panel_show_count + 1)
    switch: ->
        $(SugarDash.current).fadeOut()
        SugarDash.next.fadeIn()
        SugarDash.current = SugarDash.next
        SugarDash.next = $(SugarDash.current).next(SugarDash.panelFilter)
        if SugarDash.next.length == 0
            SugarDash.next = $(SugarDash.container.children(SugarDash.panelFilter)).first()
        SugarDash.refresh(SugarDash.next.data('panel_id'))
}
