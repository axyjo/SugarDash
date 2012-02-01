var fs = require('fs');

exports.init = function() {
    return {
        extensions: ['hbt'],
        assetType: 'html',
        contentType: 'text/x-handlebars-template',
        compile: function(path, options, cb) {
            cb(fs.readFileSync(path, 'utf8'));
        },
    };
};

