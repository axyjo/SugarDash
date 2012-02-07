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
if (ss.env == 'production') ss.client.packAssets();

var server = http.Server(ss.http.middleware);
server.listen(3000);

ss.start(server);
