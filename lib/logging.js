var lawgs  = require('lawgs');
var util   = require('util');
var config = require('./config');
var os     = require('os');

lawgs.config({
  uploadMaxTimer: 1000,
  uploadBatchSize: 10,
  showDebugLogs: true,
});

var logger = lawgs.getOrCreate(config.CLOUDWATCH_GROUP); // create log group

/**
 * Replace console.xxxx
 */
exports.log   = mklog('log');
exports.info  = mklog('info');
exports.warn  = mklog('warn');
exports.error = mklog('error');

function mklog(level) {
  return function() {
    var message = util.format.apply(null, arguments);
    console.log('>>', new Date().toISOString(), '--', level.toUpperCase(), '--', message);
    logger.log('backend', level.toUpperCase() + ': ' + message, {
      level: level,
      hostname: os.hostname(),
    });
  };
}

/**
 * Can be used as a StreamWriter.
 */
exports.stream = {
  write: function(msg) {
    exports.info(msg.trim());
  }
};
