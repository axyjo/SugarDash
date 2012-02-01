// My SocketStream app

var http = require('http')
  , ss = require('socketstream');

_ = require('underscore');

ss.client.define('main', {
  view:   'app.jade',
  css:    ['libs', 'app.styl'],
  code:   ['libs', 'modules', 'main'],
  tmpl:   ['panels'],
});

ss.http.router.on('/', function(req, res) {
  res.serve('main');
});

// Remove to use only plain .js, .html and .css files if you prefer
ss.client.formatters.add(require('ss-coffee'));
ss.client.formatters.add(require('ss-jade'));
ss.client.formatters.add(require('ss-stylus'));
// Add a formatter for Handlebar templates
ss.client.formatters.add(require('./formatters/hbt'));

// Minimise and pack assets if you type SS_ENV=production node app
if (ss.env == 'production') ss.client.packAssets();

var server = http.Server(ss.http.middleware);
server.listen(3000);

ss.start(server);
