SugarDash = {
    panels: ['new_hires', 'birthdays', 'local_news']
    init: ->
        this.container = $("#container")
        $(window).resize()
        this.populate()
        $("#container p").fadeOut()
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
            console.log($(template_id).html())
            template = Handlebars.compile($(template_id).html())
            console.log(template)
            output = template({
            })
            console.log(output)

            e.html(output)
            e.appendTo("#container")
        this.container.children('div').first().show("fade", 'easeInSine', 2000)
    switch: ->
        current = this.container.find('.visible')
        next = current.next()
        if next.length == 0
            next = this.container.children('div').first()
        current.removeClass 'visible'
        next.addClass 'visible'
}
