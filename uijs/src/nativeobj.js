var EventEmitter = require('uijs').events.EventEmitter;

window.uijs_native_objects = {}; // used to emit events from native code
window.uijs_emit_event = function(objid, event, args) {
  var obj = window.uijs_native_objects[objid];
  if (!obj) {
    console.warn('unable to emit event ' + event + ' from native object with id ' + objid + ' because object not found');
    return; // object not found
  }

  return obj.emit(event, args);
};

module.exports = function(type, id, options) {
  var obj = new EventEmitter();

  var cordova = window.cordova || window.Cordova;
  if (!cordova) {
    console.warn('No phonegap environment. Unable to create native object of type ' + type);
    obj.call = function(method, args, callback) {
      callback = callback || function() {};
      return callback();
    };
    
    return obj;
  }

  // add object to global hash
  window.uijs_native_objects[id] = obj;

  // native.call(method, args, callback)
  // call `method` with `args` on the native object.
  // `args` can be any type of JSONable object
  obj.call = function(method, args, callback) {
    callback = callback || function() {};

    function success() {
      var args = [];

      args.push(null); // err
      
      for (var i = 0; i < arguments.length; ++i) {
        args[i] = arguments[i];
      }

      return callback.apply(obj, args);
    }

    function failure(err) {
      return callback.call(obj, err);
    }

    return cordova.exec(success, failure, 'org.uijs.native', 'invoke', [ method, type, id, JSON.stringify(args) ]);
  };

  obj.call('init', options, function(err) {
    if (!err) {
      alert('init error: ' + err.toString());
    }
  });

  return obj;
};