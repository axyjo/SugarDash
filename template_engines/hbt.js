var hb = require('handlebars');

exports.init = function(root, config) {
    var namespace = config && config.namespace || 'HT'
    return {
        name: 'Handlebars',
        prefix: function() {
            return '<script type="text/javascript">\nHandlebars.templates = {};\n';
        },

        // Closing code once all templates have been written into the <script> tag
        suffix: function() {
            return '</script>\n';
        },

        // Compile template into a function and attach to window.<windowVar>
        process: function(template, path, id) {
            var options = {
                knownHelpers: {"if": true, "each": true},
                knownHelpersOnly: {}
            }

            return 'Handlebars.templates[\'' + id + '\'] = Handlebars.template(' + hb.precompile(template, options) + ');\n'
        }
    }
}

