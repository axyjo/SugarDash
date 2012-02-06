var hb = require('handlebars');

exports.init = function(root, config) {
    var namespace = config && config.namespace || 'HT'
    return {
        name: 'Handlebars',
        prefix: function() {
            return '<script type="text/javascript">\n(function() {\n  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};\n';
        },

        // Closing code once all templates have been written into the <script> tag
        suffix: function() {
            return '})()\n</script>\n';
        },

        // Compile template into a function and attach to window.<windowVar>
        process: function(template, path, id) {
            var options = {
                knownHelpers: {'if': true, 'divide': true, 'each': true},
                knownHelpersOnly: {}
            }
            return 'Handlebars.templates[\'' + id + '\'] = Handlebars.template(' + hb.precompile(template, options) + ');\n'
        }
    }
}

