// My SocketStream app

var http = require('http'),
    ss = require('socketstream');

var sugar_auth_token = null;

_ = require('underscore');
require('colors');

ss.client.define('main', {
  view:   'app.jade',
  css:    ['app.css'],
  code:   ['libs/jquery-1.7.1.js', 'libs', 'modules', 'main'],
  tmpl:   ['panels', 'partials'],
});

ss.http.router.on('/', function(req, res) {
  res.serve('main');
});

// Remove to use only plain .js, .html and .css files if you prefer
ss.client.formatters.add(require('ss-coffee'));
ss.client.formatters.add(require('ss-jade'));

// Add a formatter for Handlebar templates
ss.client.formatters.add(require('./formatters/hbt'));

// Use server-side compiled Handlebars templates.
ss.client.templateEngine.use(require('./template_engines/hbt'));

// Minimise and pack assets if you type SS_ENV=production node app
// Otherwise, log memory usage.
if (ss.env == 'production') {
    ss.client.packAssets();
} else {
    setInterval(function() {
        mem = Math.round(process.memoryUsage().rss / 1024 / 1024 * 10)/10
        console.log("RAM Usage: %s MB", mem);
    }, 30*1000);
}

process.env.GH_USER = process.env.GH_USER || ""
process.env.GH_PASS = process.env.GH_PASS || ""
process.env.SUGAR_USER = process.env.SUGAR_USER || ""
process.env.SUGAR_PASS = process.env.SUGAR_PASS || ""

var server = http.Server(ss.http.middleware);
server.listen(3000);

ss.start(server);
