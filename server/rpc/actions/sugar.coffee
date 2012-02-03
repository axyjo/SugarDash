exports.actions = (req, res, ss) ->
    class SugarInternal
        @get: -> @instance ?= new @

        call: (cb, func, args, params) ->
            if(!_.isEmpty(SugarInternal::getToken()))
                @_call cb, func, args, params
            else
                console.log func, "failed: not authenticated."

        login: (username, password) ->
            loginData = [{
                user_name: username,
                password: password,
                encryption: 'PLAIN',
            }, 'SugaDash', []]
            # Only login can bypass the auth check for call.
            cb = (data) ->
                console.log "SESSION ID:", data.id
                SugarInternal::setToken data.id
                res data.name_value_list
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
                console.log "No auth token present."
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
                        console.log "Non JSON response:", resp.join('')
                        console.log "Error:", error

            request.write data
            request.end()
            console.log("Request sent.")

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

            @si = si

            @cb = cb || ->
                console.log "No callback passed to QuerySI"

            @data = null
            @validated = false
            @executed = false
            @

        logQuery: =>
            if @fields?
                all_fields = @fields.join(', ')
            else
                all_fields = '*'

            query = "SELECT " + all_fields + " FROM " + @module.toLowerCase()
            if @where_clause?
                query += " WHERE " + @where_clause

            if @order_clause?
                query += " ORDER BY " + @order_clause

            query += " LIMIT " + @limit_val
            if @offset_val? and @offset_val != 0
                query += " OFFSET " + @offset_val

            console.log query

        execute: =>
            @._validate()
            @.logQuery()
            if @validated
                obj = @
                callback = (data) ->
                    obj.data = data
                    obj.cb(obj)
                @si.call(callback, 'get_entry_list', [SugarInternal::token(), @module, @where_clause, @order_clause, @offset_val, @fields, null, @limit_val])
                @executed = true
            @

        groupBy: (column) =>
            entry_list = {}
            for entry in @data.entry_list
                val = entry.name_value_list[column].value
                if !_.isArray entry_list[val]
                    entry_list[val] = []
                entry_list[val].push(entry)
            @data.entry_list = entry_list
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
            clause = table + '.' + field + ' ' + operator + ' "' + value + '"'
            @.addWhereClause clause
            @

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

        order: (o) =>
            @order_clause = o
            @

        newest: =>
            @.order("date_entered DESC")
            @

        oldest: =>
            @.order("date_entered ASC")
            @

        limit: (n) =>
            @limit_val = n
            @

        all: =>
            # TODO: Come up with a better way to do this.
            @.limit(100000)
            @

        from: (mod) =>
            @module = mod
            @

        uuid: (id) =>
            @uuid_val = id
            @

        mergeDate: (date_field, dateParam) =>
            moment = require('moment')
            epoch = moment(0)
            for entry in @data.entry_list
                value = entry.name_value_list[date_field].value
                date = moment(value)
                new_value = date.diff epoch, dateParam+"s"
                entry.name_value_list[date_field+"_converted"] = {name: date_field+"_converted", value: new_value}
            # return this
            @

        _validate: () =>
            if not SugarInternal::token()?
                false

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
        q = new Defects {uuid: input.uuid || null}, process.si, (results) ->
            return_data results
        statuses = ['Pending', 'Pending Review', 'PendingPM', 'Closed']
        joneses_release = '9385ad44-3ead-6617-b217-4d02b12a8cd3'
        sprint_number = input.sprint_number || jonesesCurrentSprintWeek()
        q.in('status', statuses).where('fixed_in_release', joneses_release).where('sprint_number_c', sprint_number, '=', true).all().execute()

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
            q.select(['picture', 'date_entered', 'department', 'full_name']).newest().limit(20).execute()
        getMilestoneDates: (input) ->
            data = [
                {date: Date.parse('Feb 29, 2012'), title: '6.4.1 GA'},
                {date: Date.parse('Mar 28, 2012'), title: '6.4.2 GA'},
                {date: Date.parse('Apr 25, 2012'), title: '6.4.3 GA'},
                {date: Date.parse('May 23, 2012'), title: '6.4.4 GA'},
                {date: Date.parse('Feb 3, 2012'), title: 'Caramel coding complete'},
                {date: Date.parse('Mar 2, 2012'), title: 'Caramel QA complete'},
                {date: Date.parse('Mar 14, 2012'), title: '6.5b1'},
                {date: Date.parse('Mar 21, 2012'), title: '6.5b2'},
                {date: Date.parse('Mar 28, 2012'), title: '6.5b3'},
                {date: Date.parse('Apr 4, 2012'), title: '6.5b4'},
                {date: Date.parse('Apr 11, 2012'), title: '6.5b5'},
                {date: Date.parse('Apr 18, 2012'), title: '6.5b6'},
                {date: Date.parse('Apr 25, 2012'), title: '6.5RC1'},
                {date: Date.parse('May 9, 2012'), title: '6.5RC2'},
                {date: Date.parse('May 23, 2012'), title: '6.5RC3'},
                {date: Date.parse('Jun 6, 2012'), title: '6.5 GA'},
            ]
        getNewBugs: (input) ->
            input = validateInput(input)
            q = new Defects {uuid: input.uuid || null}, process.si, (results) ->
                return_data results
            q.newest().limit(10)

        getJonesesSprint: (input) ->
            input = validateInput(input)
            getJoneses input

        getCurrentJoneses: (input) ->
            input = validateInput(input)
            input.sprint_number = jonesesCurrentSprintWeek()
            getJoneses input

        getPreviousJoneses: (input) ->
            input = validateInput(input)
            input.sprint_number = jonesesCurrentSprintWeek() - 1
            getJoneses input

        _rawCall: (func, args, params) ->
            si = process.si.get()
            request = si._call(func, args, params)
            process.once "sugar_success_"+func, (data) ->
                res data
    }


