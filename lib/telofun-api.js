var soap = require('soap');
var config = require('./config');

var location = config.TELOFUN_ENDPOINT;

module.exports = function(callback) {
  return soap.createClient(location, function(err, client) {
    if (err) return callback(err);
    if (!client.GetNearestStations) return callback(new Error('could not find GetNearestStations'));

    var auth_header = {
      Username: config.TELOFUN_USER,
      Password: config.TELOFUN_PASSWORD,
    };

    client.addSoapHeader({ AuthHeader: auth_header }, "", "__tns__", "http://tempuri.org/");

    var params = {
      longitude: 32.066246,
      langitude: 34.77754,
      radius: 1000000,
      maxResults: 10000,
    };

    return client.GetNearestStations(params, function(err, results, body) {
      if (err) return callback(err);
      return callback(null,
        results &&
        results.GetNearestStationsResult &&
        results.GetNearestStationsResult.StationsCloseBy &&
        results.GetNearestStationsResult.StationsCloseBy.Station);
    });
  });
};
