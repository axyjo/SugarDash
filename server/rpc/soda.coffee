exports.actions = (req, res, ss) ->
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

    return {

        getSodaResults: (input) ->
            input = validateInput input
            branch = input.branch || '64_Joneses'

            mysql = require 'mysql'
            client = mysql.createClient {
                host: process.env.SODA_HOST
                port: process.env.SODA_PORT
                user: process.env.SODA_USER
                password: process.env.SODA_PASS
                database: process.env.SODA_DB
            }

            segments = ['Passed', 'Failed', 'Blocked']
            results = {
                uuid_val: input.uuid
            }
            strings = [' - ', 'SodaBuild-', '', "lib\\/.*", 'SodaBuild%'+branch+'%']

            query = "SELECT REPLACE(SUBSTRING_INDEX(builds.build_id , ?, 1) , ?, ?) as jenkins, test_data.build_id as id, COUNT(test_data.test_id) AS total,
            (COUNT(*) - SUM(blocked)) AS run,
            SUM(blocked) AS Blocked,
            SUM(test_result) AS Failed,
            (COUNT(*) - SUM(test_result)) AS Passed
            FROM test_data LEFT JOIN builds ON test_data.build_id = builds.id
            WHERE test_data.testfile_name NOT REGEXP ?
            AND builds.build_id LIKE ?
            GROUP BY builds.id"

            parsed = {}
            client.query query, strings, (err, mysql_results, fields) ->
                console.log("ERR:", err)
                if !err?
                    parsed[branch] = {}
                    for result in mysql_results
                        build = result.jenkins
                        parsed[branch][build] = {} if !parsed[branch][build]?
                        for segment in segments
                            parsed[branch][build][segment] = result[segment]

                    results.data = getStackedArea parsed, segments
                    return_data results
                    res true

                else
                    res false
    }


