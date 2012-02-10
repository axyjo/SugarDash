exports.actions = (req, res, ss) ->

    moment = require('moment')
    log = (args...)->
        str = "SugarCRM: ".blue + args.join(' ')
        console.log str

    class SugarInternal
        @get: -> @instance ?= new @

        call: (cb, func, args, params) ->
            if(!_.isEmpty(SugarInternal::getToken()))
                @_call cb, func, args, params
            else
                if !_.isEmpty(process.env.SUGAR_USER) and !_.isEmpty(process.env.SUGAR_PASS)
                    @login process.env.SUGAR_USER, process.env.SUGAR_PASS, ->
                        @_call cb, func, args, params
                else
                    log "Not authenticated.".red

        login: (username, password, callback = null) ->
            loginData = [{
                user_name: username,
                password: password,
                encryption: 'PLAIN',
            }, 'SugaDash', []]
            # Only login can bypass the auth check for call.
            cb = (data) ->
                log "SESSION ID =".green, data.id.toString().green
                SugarInternal::setToken data.id
                res data.name_value_list
                ss.publish.all "refresh", "refresh"
                callback.call()
            request = @_call(cb, "login", loginData)

        setToken: (t) ->
            process.sugar_auth_token = t

        getToken: ->
            process.sugar_auth_token

        token: ->
            val = SugarInternal::getToken()
            if val?
                val
            else
                log "No auth token present.".yellow
                null

        _call: (cb, func, args, params) ->
            https = require('https')

            params = params || {}
            data = JSON.stringify(params)
            options = {
                host: 'sugarinternal.sugarondemand.com',
                port: 443,
                path: '/service/v4/rest.php?'+@_getQueryString(func, args),
                method: 'POST',
                headers: {
                    'Content-Length': Buffer.byteLength(data, 'utf8'),
                },
            }
            resp = []
            request = https.request options, (response) ->
                response.on "data", (chunk) ->
                    resp.push(chunk)
                response.on "end", ->
                    try
                        response_body = JSON.parse resp.join('')
                        cb response_body
                    catch error
                        log "Non JSON response:".yellow, resp.join('')
                        log "Error:".red, error

            request.write data
            request.end()
            log "Request sent for", func, "."

        _getQueryString: (func, args) ->
            data = {
                method: func,
                input_type: "JSON",
                response_type: "JSON",
            }
            if(!_.isNull(args))
                data.rest_data = JSON.stringify(args)
            require('querystring').stringify data


    class SugarRecord
        constructor: (params, si, cb) ->
            @fields = params.select || null
            @module = params.from || null
            @where_clause = params.where || []
            @order_clause = params.order || null
            @offset_val = params.offset || 0
            @limit_val = params.limit || null
            @uuid_val = params.uuid || null
            @group_by = params.groupBy || null
            @count_by = params.countBy || null
            @filters = params.filters || []
            @filter_lim = params.filter_limit || 0

            @si = si
            @orig_data = []

            @cb = cb || ->
                log 'No callback passed to QuerySI'.warn

            @startDate = null
            @endDate = null
            @time = null

            @data = null
            @validated = false
            @executed = false
            @

        logQuery: (failed = false) =>
            if !@validated
                @._validate()

            if @fields?
                all_fields = @fields.join(', ')
            else
                all_fields = '*'

            if @count_by?
                all_fields += ', COUNT(' + @count_by + ')'

            query = "SELECT " + all_fields + " FROM " + @module.toLowerCase()
            if @where_clause?
                query += " WHERE " + @where_clause

            if @group_by?
                query += " GROUP BY " + @group_by

            if @order_clause?
                query += " ORDER BY " + @order_clause

            query += " LIMIT " + @limit_val
            if @offset_val? and @offset_val != 0
                query += " OFFSET " + @offset_val

            if failed
                query = "FAILED QUERY: ".red + query.red
            else
                query = query.cyan

            if @endDate?
                query += (" (" + @time + " s)").blue
            else
                query = "INCOMPLETE QUERY: ".blue + query

            log query

        execute: =>
            @._validate()
            if @validated
                obj = @
                callback = (data) ->
                    obj.data = data

                    if data.entry_list? and _.isArray data.entry_list
                        # Flatten the object.
                        for entry, i in data.entry_list
                            new_data = {}
                            for key, value of entry.name_value_list
                                new_data[key] = value.value
                            data.entry_list[i] = new_data

                        # Calculate ages.
                        now = moment()
                        for entry, i in data.entry_list
                            if entry.date_entered?
                                record = _parseUTCDate entry.date_entered
                                data.entry_list[i].date_entered_age = record.diff now
                            if entry.date_modified?
                                record = _parseUTCDate entry.date_modified
                                data.entry_list[i].date_modified_age = record.diff now
                            if entry.date_closed?
                                record = _parseUTCDate entry.date_closed
                                data.entry_list[i].date_closed_age = record.diff now

                    # Run any filters on the data.
                    if obj.filters? and _.isArray obj.filters
                        for filter in obj.filters
                            # Generate a filter iterator
                            switch filter[1]
                                when "=="
                                    iterator = (entry) ->
                                        entry[filter[0]] == filter[2]
                                when "!="
                                    iterator = (entry) ->
                                        entry[filter[0]] != filter[2]
                                when ">"
                                    iterator = (entry) ->
                                        entry[filter[0]] > filter[2]
                                when "<"
                                    iterator = (entry) ->
                                        entry[filter[0]] < filter[2]
                                when ">="
                                    iterator = (entry) ->
                                        entry[filter[0]] >= filter[2]
                                when "<="
                                    iterator = (entry) ->
                                        entry[filter[0]] <= filter[2]

                            data.entry_list = _.filter data.entry_list, iterator

                    if obj.filter_lim? and _.isNumber obj.filter_lim and obj.filter_lim != 0
                        data.entry_list = data.entry_list.slice(0, obj.filter_lim - 1)

                    # Group the data as requested.
                    if obj.group_by?
                        obj._groupBy(obj.group_by)
                    else if obj.count_by?
                        obj._countBy(obj.count_by)

                    # Log the query.
                    obj.endDate = new Date()
                    obj.time = (obj.endDate - obj.startDate)/1000
                    obj.logQuery()
                    obj.executed = true

                    try
                        obj.cb(obj)
                    catch e
                        log e
                @startDate = new Date()
                try
                    @si.call(callback, 'get_entry_list', [SugarInternal::token(), @module, @where_clause, @order_clause, @offset_val, @fields, null, @limit_val])
                catch e
                    @.endDate = new Date()
                    @.time = (obj.endDate - obj.startDate)/1000
                    @.logQuery(true)
            @

        groupBy: (column) =>
            @group_by = column
            @

        _groupBy: (column) =>
            entry_list = {}
            for entry in @data.entry_list
                val = entry[column]
                if !_.isArray entry_list[val]
                    entry_list[val] = []
                entry_list[val].push(entry)
            @orig_data.push @data
            @data.entry_list = entry_list
            @

        countBy: (column) =>
            @count_by = column
            @

        _countBy: (column) =>
            @._groupBy column
            entry_list = {}
            for key, value of @data.entry_list
                if not entry_list[key]?
                    entry_list[key] = value.length
            @orig_data.push @data
            @data.entry_list = entry_list
            @

        filter: (field, condition, value) =>
            if field? and condition? and value?
                @filters.push [field, condition, value]
            @

        filter_limit: (filter_limit) =>
            if filter_limit?
                @filter_limit = filter_limit
            @

        select: (fields) =>
            if _.isString fields
                @fields = fields.split(',')
            else if _.isArray fields
                @fields = fields
            @

        where: (field, value, operator = '=', custom = false, table = false) =>
            if not table
                table = @module.toLowerCase()
            if custom
                table += '_cstm'
            clause = table + '.' + field + ' ' + operator
            if value?
                clause += ' "' + value + '"'
            @.addWhereClause clause

        addWhereClause: (clause) =>
            if _.isString @where_clause
                @where_clause = [clause, @where_clause]
            else if _.isArray @where_clause
                @where_clause.push clause
            else
                @where_clause = [clause]
            @

        in: (field, values, custom = false) =>
            table = @module.toLowerCase()
            if custom
                table += '_cstm'

            clause = table + '.' + field + ' IN ('
            for value in values
                clause += '"' + value + '", '
            clause = clause.substr(0, clause.length - 2) + ')'
            @.addWhereClause clause
            @

        notEmpty: (field, custom = false) =>
            table = @module.toLowerCase()
            if custom
                table += '_cstm'

            @.where(field, '', '<>', custom)

        order: (o) =>
            @order_clause = o
            @

        newest: =>
            @.order("date_entered DESC")

        oldest: =>
            @.order("date_entered ASC")

        limit: (n) =>
            @limit_val = n
            @

        all: =>
            # TODO: Come up with a better way to do this.
            @.limit(100000)

        from: (mod) =>
            @module = mod
            @

        uuid: (id) =>
            @uuid_val = id
            @

        callback: (c) =>
            @cb = c
            @

        mergeDate: (date_field, dateParam) =>
            epoch = moment(0)
            for entry in @data.entry_list
                value = entry[date_field]
                date = moment(value)
                new_value = date.diff epoch, dateParam+"s"
                entry[date_field+"_converted"] = new_value
            # return this
            @

        _parseUTCDate = (str) ->
            moment str, "YYYY-MM-DD HH:mm:ss"

        _validate: () =>
            if not SugarInternal::token()?
                false

            # Group by takes precedence if both are specified.
            if @count_by and @group_by
                @count_by = null


            if @fields? and not _.isArray @fields
                if _.isString @fields
                    if @fields == "*"
                        @fields = null
                    else
                        @fields = @fields.split(',')
                else
                    @fields = null

            if not @module? or not _.isString @module
                # TODO: throw an exception
                false

            if @where_clause? and not _.isString @where_clause
                if _.isArray @where_clause
                    @where_clause = @where_clause.join(' AND ')

            if not _.isString @order_clause
                @order_clause = null

            if @offset_val? and _.isNaN @offset_val
                @offset_val = 0

            if @limit_val? and _.isNaN @limit_val
                @limit_val = null

            @validated = true

    class Users extends SugarRecord
        constructor: (params, si, cb) ->
            params.from = 'Users'
            super params, si, cb

    class Bugs extends SugarRecord
        constructor: (params, si, cb) ->
            params.from = 'Bugs'
            super params, si, cb

    class Defects extends Bugs
        constructor: (params, si, cb) ->
            super params, si, cb
            @.where('type', 'Defect')

    class Features extends Bugs
        constructor: (params, si, cb) ->
            super params, si, cb
            @.where('type', 'Feature')

    class SatisfactionSurvey extends SugarRecord
        constructor: (params, si, cb) ->
            params.from = 'csurv_SurveyResponse'
            super params, si, cb

    class Opportunities extends SugarRecord
        constructor: (params, si, cb) ->
            params.from = 'Opportunities'
            super params, si, cb

    appName = 'SugarDash'

    countBy = (data, column) ->
        data = groupBy data, column
        entry_list = {}
        for value in data.entry_list
            if _.isNaN entry_list[value]
                entry_list[val] = value.size
        data.entry_list = entry_list

        # return data
        data

    return_data = (query) ->
        if _.isObject(query) and _.isString(query.uuid_val)
            ss.publish.all 'response_'+query.uuid_val, query
            res true
        else
            res query

    jonesesCurrentSprintWeek = ->
        # JS Date of Week for Wednesday
        wednesday = 3
        now = new Date()
        endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()+1)
        startOfYear = new Date(now.getFullYear(), 0, 1)

        # Number of days since first wednesday of year:
        # milliseconds since Jan 1 =  endOfToday - startOfYear
        # days from Jan 1 to first Wed: wednesday - startOfYear.getDay()
        numDays = (endOfToday - startOfYear)/(24*60*60*1000) - (wednesday - startOfYear.getDay())

        # If we have a negative number, that means we're in last year's final sprint, so calculate based on the end of the previous year
        if numDays < 0
            startOfLastYear = new Date(now.getFullYear() - 1)
            endOfLastYear = new Date(now.getFullYear(), now.getMonth(), 0)
            numDays = (endOfLastYear - startOfYear)/(24*60*60*1000) - (wednesday - startOfYear.getDay())

        # sprint number is the ceiling of number of weeks since first wednesday
        Math.ceil(numDays/7)

    process.si = SugarInternal.get()

    validateInput = (input) ->
        input = input || {}
        input.uuid = input.uuid || null
        input

    getJoneses = (input) ->
        q = new Defects {uuid: input.uuid || null}, process.si
        statuses = ['Pending', 'Pending Review', 'PendingPM', 'Closed']
        joneses_release = '9385ad44-3ead-6617-b217-4d02b12a8cd3'
        sprint_number = input.sprint_number || jonesesCurrentSprintWeek()
        q.in('status', statuses).where('fixed_in_release', joneses_release).where('sprint_number_c', sprint_number, '=', true).all()
        q.groupBy('assigned_user_name')
        q

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

    getPie = (results) ->
        data = _.zip _.keys(results.data.entry_list), _.values(results.data.entry_list)
        data = _.sortBy data, (point) ->
            point[1]
        chart = getChart('pie', 'Joneses')
        chart.legend = {
            enabled: true,
            layout: 'vertical',
            floating: false,
            align: 'right',
            verticalAlign: 'middle',
            labelFormatter: "return this.name + ': ' + this.y;"
        }
        chart.series.push {
            type: 'pie',
            name: 'Joneses fixes by developer',
            data: data.reverse(),
        }
        chart

    getStackedBar = (chart_data, segments) ->
        chart = getChart('bar', 'Bugs by Developer/Status')
        chart.xAxis.categories = _.keys chart_data
        chart.legend = {
            enabled: true,
            layout: 'horizontal',
            floating: true,
            align: 'right',
            verticalAlign: 'top'
        }
        chart.plotOptions = {
            series: {
                stacking: 'normal'
            }
        }

        for segment in segments
            data = []
            for key, value of chart_data
                if value[segment]?
                    data.push value[segment]
                else
                    data.push 0

            chart.series.push {
                name: segment,
                data: data
            }
        chart

    getDeveloperBugs = (input) ->
        input = validateInput(input)
        q = new Defects {uuid: input.uuid}, process.si, (results) ->
            chart_data = {}
            segments = []
            for developer, bugArray of results.data.entry_list
                if !chart_data[developer]?
                    chart_data[developer] = {}
                for bug in bugArray
                    if !_.include(segments, bug.status)
                        segments.push bug.status
                    if !chart_data[developer][bug.status]?
                        chart_data[developer][bug.status] = 0
                    chart_data[developer][bug.status]++

            results.data = getStackedBar chart_data, segments
            return_data results
        if input.release?
            q.where('fixed_in_release', input.release).all()
        else
            q.limit(500)
        q.groupBy('assigned_user_name').execute()

    return {
        getServerInfo: ->
            request = call("get_server_info", '')
            process.once "sugar_success", (data) ->
                res data
        login: (username, password) ->
            process.si.login(username, password)
            res true

        loggedIn: ->
            res process.si.get().loggedIn()
        getNewEmployees: (input) ->
            input = validateInput(input)
            q = new Users {uuid: input.uuid}, process.si, (results) ->
                return_data results
            q.select(['picture', 'date_entered', 'department', 'full_name']).newest().limit(9).execute()

        getSatisfaction: (input) ->
            input = validateInput input
            q = new SatisfactionSurvey {uuid: input.uuid}, process.si, (results) ->
                for result in results.data.entry_list
                    result.responses = []
                    for i in [1..6]
                        if result["question_"+i]? and !_.isEmpty result["question_"+i]
                            switch parseInt(result["question_"+i])
                                when 10, 9, 8
                                    val = "happy"
                                when 7, 6, 5
                                    val = "neutral"
                                else
                                    val = "sad"
                            result.responses.push val
                        else
                            result.responses.push false
                return_data results
            q.newest().limit(10).execute()

        getNewLargeOpportunities: (input) ->
            input = validateInput input
            q = new Opportunities {uuid: input.uuid}, process.si, (results) ->
                return_data results
            q.order('amount DESC').addWhereClause('opportunities.date_entered > NOW() - INTERVAL 2 WEEK').limit(10)
            q.execute()

        getNewFeaturesChart: (input) ->
            input = validateInput(input)
            releases = ["_6.5.0", "_6.6.0"]
            release_ids = ["b77dc99e-fd80-384d-51eb-4c1123bfa912", "cac9b8c9-be48-552b-6089-4f063d8cc0d3"]
            q = new Features {uuid: input.uuid}, process.si, (results) ->
                return_data results
            q.limit(500).in('fixed_in_release', release_ids).execute()

        getDeveloperBugsCaramel: (input) ->
            input = validateInput(input)
            input.release = "b77dc99e-fd80-384d-51eb-4c1123bfa912"
            getDeveloperBugs input

        getNewBugs: (input) ->
            input = validateInput(input)
            q = new Defects {uuid: input.uuid || null}, process.si, (results) ->
                return_data results
            q.newest().limit(10)

        getJonesesSprint: (input) ->
            input = validateInput(input)
            q = getJoneses input

        getCurrentJoneses: (input) ->
            input = validateInput(input)
            input.sprint_number = jonesesCurrentSprintWeek()
            q = getJoneses input
            q.callback( (results) ->
                results.data = getPie results
                return_data results
            ).groupBy(null).countBy('assigned_user_name').execute()

        getPreviousJoneses: (input) ->
            input = validateInput(input)
            input.sprint_number = jonesesCurrentSprintWeek() - 1
            q = getJoneses input
            q.callback( (results) ->
                results.data = getPie results
                return_data results
            ).groupBy(null).countBy('assigned_user_name').execute()

        getJonesesChart: (input) ->
            input = validateInput input
            q = new Defects {uuid: input.uuid || null}, process.si, (results) ->
                chart = getChart input.chart_type, input.chart_title, input.xaxis_title, input.yaxis_title
                chart.xAxis.categories = _.keys results.data.entry_list
                chart.series.push {
                    type: 'line'
                    name: 'Joneses Chart'
                    data: _.values results.data.entry_list
                }
                results.data = chart
                return_data results
            statuses = ['Pending', 'Pending Review', 'PendingPM', 'Closed']
            joneses_release = '9385ad44-3ead-6617-b217-4d02b12a8cd3'
            q.in('status', statuses).where('fixed_in_release', joneses_release).where('sprint_number_c', '', '<>', true)
            q.countBy('sprint_number_c').all().execute()

        _rawCall: (func, args, params) ->
            request = process.si._call (data)->
                res data
            , func, args, params
    }


