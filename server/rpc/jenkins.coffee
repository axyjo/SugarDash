exports.actions = (req, res, ss) ->
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
        chart.xAxis.categories = _.keys chart_data
        data = {}
        for segment in segments
            data[segment] = []

        for build, obj of chart_data
            for segment in segments
                if obj[segment]?
                    data[segment].push obj[segment]
                else
                    data[segment].push 0

        for segment, value of data
            chart.series.push {
                name: segment
                data: value
            }
        chart

    getJob = (input, cb) ->
        console.log "Got request", input.uuid
        host = 'eng-ci1.sjc.sugarcrm.pvt'
        path = '/view/'+input.view+'/job/'+input.job+'/api/json?depth=1'
        http = require('http')
        client = http.createClient 8080, host
        request = client.request 'GET', path

        contents = []

        request.on 'response', (response) ->
            response.on "data", (chunk) ->
                if(!_.isEmpty(chunk))
                    contents.push chunk
            response.on "end", ->
                d = JSON.parse(contents.join(''))
                cb.call(this, d)
        request.end()
        console.log 'Request sent.'

    return {
        getChart: (input) ->
            segments = ['Passed', 'Failed', 'Skipped']
            cb = (d) ->
                d = d.builds.slice 0, 14
                new_data = {}
                for test in d
                    values = {}
                    for action in test.actions
                        if action.urlName == "testReport"
                            values = action
                            break
                    if values.failCount?
                        # If failCount is undefined, the build is still in progress.
                        data = {
                            "Passed": values.totalCount - values.failCount - values.skipCount
                            "Failed": values.failCount
                            "Skipped": values.skipCount
                        }
                        console.log test.number, data
                        new_data[test.number] = data
                ret = {
                    uuid_val: input.uuid
                    data: getStackedArea new_data, segments
                }
                return_data ret
            getJob input, cb

        getLastFailure: (input) ->
            cb = (d) ->
                data = {}

                # Find latest failure.
                for build in d.builds
                    if build.result == "FAILURE"
                        culprits = []
                        for culprit in build.culprits
                            culprits.push culprit.fullName

                        time = (new Date(build.timestamp)).toString()
                        lastFailed = {names: culprits.join(', '), number: build.number, time: time}
                        break

                if !lastFailed?
                    lastFailed = {name: "nobody", timestamp: 0}

                resp = {
                    uuid_val: input.uuid
                    data: lastFailed
                }
                return_data resp
            getJob input, cb
    }
