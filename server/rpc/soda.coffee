exports.actions = (req, res, ss) ->
    jsdom = require 'jsdom'
    parsed = parsed || {}

    log = (args...)->
        str = "SODA: ".blue + args.join(' ')
        console.log str

    return_data = (data) ->
        if _.isObject(data) and _.isString(data.uuid_val)
            ss.publish.all 'response_'+data.uuid_val, data
            res true
        else
            res data

    validateInput = (input) ->
        input = input || {}
        input.uuid = input.uuid || null
        input

    getChart = (type, title, xaxis, yaxis) ->
        {
            chart: {
                defaultSeriesType: type || 'line'
            }

            credits: {
                text: 'from: Sugar Internal'
                href: 'http://sugarinternal.sugarondemand.com'
            }

            title: {
                text: title || 'CHART TITLE NOT SET'
            }

            xAxis: {
                title: {
                    text: xaxis || null
                }
            }

            yAxis: {
                title: {
                    text: yaxis || null
                }
            }

            plotOptions: {
                line: {
                    dataLabels: {
                        enabled: true
                    }
                    enableMouseTracking: false
                }
                pie: {
                    dataLabels: {
                        enabled: false,
                    },
                    showInLegend: true,
                }
            }
            series: []
        }

    getStackedArea = (chart_data, segments) ->
        chart = getChart('area', 'Build Status')
        # Manually override colours so that they make sense.
        chart.colors = ['#46A546', '#9D261D', '#F89406']
        chart.legend = {
            enabled: true,
            layout: 'horizontal',
            floating: true,
            align: 'right',
            verticalAlign: 'top'
        }
        chart.plotOptions = {
            area: {
                stacking: 'normal'
            }
        }
        for build, obj of chart_data
            chart.xAxis.categories = _.keys chart_data[build]
            for segment in segments
                data = []
                for key, value of obj
                    if value[segment]?
                        data.push value[segment]
                    else
                        data.push 0

                chart.series.push {
                    name: segment,
                    data: data
                }
        chart

    jquery_path = "http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"
    base_url = "http://soda-reporting/soda/"


    branches = [650]

    getSummaryData = (branch, build, branch_url, state) ->
        url = branch_url + build + "/summary.html"
        config = {
            html: url
            scripts: [jquery_path]
            done: (errors, window) ->
                if errors? and !_.isEmpty(errors)
                    log errors
                $ = window.jQuery
                container = $("#totals")
                data = {
                    "Passed": parseInt container.find('.td_footer_passed').html()
                    "Failed": parseInt container.find('.td_footer_failed').html()
                    "Blocked": parseInt container.find('.td_footer_skipped').html()
                }
                log "Got data for", branch+'-'+build, JSON.stringify(data)
                parsed[branch] = {} if !parsed[branch]?
                parsed[branch][build] = {} if !parsed[branch][build]?
                parsed[branch][build] = data
                state.complete(branch+"-"+build)
        }

        jsdom.env(config)

    stack = "stack47"
    browser = "firefox"
    fetchSodaResults = (state) ->
        log "Called fetchSodaResults"
        for branch in branches
            log "Fetching branch", branch
            branch_url = base_url + stack+"/"+branch+"/"+browser+"/"
            jsdom.env {
                html: branch_url
                scripts: [jquery_path]
                done: (errors, window) ->
                    if errors? and !_.isEmpty(errors)
                        log errors
                    parsed[branch] = {}
                    $ = window.jQuery
                    buildNums = []
                    # Remove header row.
                    $('table tr:first').remove()
                    # Remove <hr> top row.
                    $('table tr:first').remove()
                    # Remove 'Parent Directory' row.
                    $('table tr:first').remove()
                    # Remove 'latest' directory row.
                    $('table tr:last').remove()
                    # Remove <hr> bottom row.
                    $('table tr:last').remove()

                    $('table').find('td a').each ->
                        # Search for the link to the directory in cell
                        directoryName = $(this).html()
                        buildNums.push directoryName.substr 0, directoryName.length-1

                    buildNums = buildNums.slice(-14)

                    for build in buildNums
                        state.add branch+"-"+build
                        getSummaryData branch, build, branch_url, state
                    state.complete 'fetch'
            }

    Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1
    class State
        constructor: (@states, @callback, @context) ->

        add: (state) ->
            this.states.push state

        complete: (state) ->
            this.states.remove(state)
            if(this.states.length <= 0)
                this.callback.call(this.context)
    return {
        getSodaResults: (input) ->
            input = validateInput input
            input.stack = input.stack || 'stack47'
            input.browser = input.browser || 'firefox'
            input.branch = input.branch || true

            segments = ['Passed', 'Failed', 'Blocked']
            results = {
                uuid_val: input.uuid
            }
            now = new Date()
            # Update soda every 6 hours.
            if process.soda? and process.sodaTime? and !_.isEmpty(process.soda) and process.sodaTime < now - 1000 * 60 * 60 * 6
                return_data process.soda
                res true
            else
                cb = ->
                    if input.branch?
                        chart_data = parsed
                        results.data = getStackedArea chart_data, segments
                        process.soda = results
                        process.sodaTime = new Date()
                        return_data results
                        res true
                    else
                        res false
                state = new State ["fetch"], cb, this
                fetchSodaResults state

    }


