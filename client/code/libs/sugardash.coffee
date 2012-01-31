SugarDash = {
    panels: ['new_hires', 'birthdays', 'local_news']
    init: ->
        this.container = $("#container")
        $(window).resize()
        this.populate()
        $("#container p").fadeOut()
        setInterval(this.switch, 5*1000)
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
            e = $ document.createElement('div')
            e.attr 'id', 'panel_'+panel
            e.addClass 'panel'
            template_id = "#tmpl-panels-"+panel
            template = Handlebars.compile($(template_id).html())
            output = template({
            })

            e.html(output)
            e.appendTo("#container")
        SugarDash.current = $(this.container).children('div').first().show("fade", 'easeInSine', 2000)
    switch: ->
        next = $(SugarDash.current).next()
        if next.length == 0
            next = $(SugarDash.container.children('div')).first()
        $(SugarDash.current).hide("slide", {direction: "right"}, 1000);
        next.show("slide", {direction: "right"}, 1000);
        SugarDash.current = next
}
