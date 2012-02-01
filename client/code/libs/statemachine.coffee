Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class State
    constructor: (@states, @callback, @context) ->

    complete: (state) ->
        this.states.remove(state)
        if(this.states.length <= 0)
            this.callback.call(this.context)
