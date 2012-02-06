var fs = require('fs');

exports.init = function() {
    return {
        extensions: ['less'],
        assetType: 'lessasdf',
        contentType: 'text/x-handlebars-template',
        compile: function(path, options, cb) {
            cb(fs.readFileSync(path, 'utf8'));
        },
    };
};

