var express        = require('express');
var path           = require('path');
var AWS            = require('aws-sdk');
var async          = require('async');
var csvdb          = require('csvdb');
var morgan         = require('morgan');

var cors           = require('./lib/cors');
var telofun_api    = require('./lib/telofun-api');
var telofun_mapper = require('./lib/telofun-mapper');
var config         = require('./lib/config');
var logging        = require('./lib/logging');

logging.info('telobike server is running...');

var overrides_url = 'https://docs.google.com/spreadsheets/d/1qjbQfj2vDWc569PIXJ-i8-2uLQk3KC1P4mz3bpGUJxI/pub?output=csv';

var server = express();

server.use(morgan('short', { stream: logging.stream }));
server.use(express.methodOverride());
server.use(cors());
server.use(express.favicon(path.join(__dirname, 'public/img/favicon.png')));

var last_read_status = {
  time: 'never',
  api: 'unknown',
  overrides: 'unknown',
};

var stations = [ ];

function read_stations() {

  logging.info('reading station information from tel-o-fun');

  last_read_status = {
    time: new Date(),
    api: 'pending',
    overrides: 'pending',
  };

  return telofun_api(function(err, updated_stations) {
    if (err || !updated_stations) {
      if (!err) err = new Error('stations array is empty');
      last_read_status.api = 'Error: ' + err.message;
      logging.error('ERROR: unable to read telofun stations:', err.message);
      return;
    }

    logging.info(updated_stations.length + ' stations retrieved');
    last_read_status.api = 'Loaded ' + updated_stations.length.toString() + ' stations';

    // map stations from tel-o-fun protocol to tel-o-bike protocol
    var mapped_stations = updated_stations.map(telofun_mapper);

    // convert to hash
    new_stations = { };
    mapped_stations.forEach(function(s) {
      // skip inactive stations
      if (s.IsActive === '0') {
        return;
      }

      new_stations[s.sid] = s;
    });

    // read overrides from google sheets
    return csvdb(overrides_url, function(err, all_overrides) {
      if (err) {
        last_read_status.overrides = 'Error: ' + err.message;
      }
      else {
        last_read_status.overrides = 'Success. Loaded ' + Object.keys(all_overrides).length.toString() + ' overrides';

        // merge overrides
        merge_overrides(new_stations, all_overrides);
      }

      // update cache (array of stations)
      stations = Object.keys(new_stations).map(k => new_stations[k]);

      return;
    });
  });
}

function merge_overrides(stations, all_overrides) {
  for (var sid in stations) {
    var s = stations[sid];

    var overrides = all_overrides[sid];
    if (overrides) {
      logging.info('found overrides for', sid);
      for (var k in overrides) {
        var val = overrides[k];
        if (val) {
          s[k] = val;
        }
      }
    }
  }
}

setInterval(read_stations, 30*1000); // update station info every 30 seconds
read_stations();

function get_tlv_stations(req, res) {
  return res.send(stations);
}

function get_tlv_city(req, res) {
  return res.send({
    "city": "tlv",
    "city_center": "32.0664,34.7779",
    "city_name": "תל-אביב יפו",
    "city_name.en": "Tel-Aviv",
    "info_url": "http://telobike.citylifeapps.com/static/en/tlv.html",
    "info_url_he": "http://telobike.citylifeapps.com/static/he/tlv.html",
    "last_update": "2011-06-15 18:47:50.982111",
    "mail": "info@fsm-tlv.com",
    "mail_tags": "This problem was reported via telobike",
    "service_name": "תל-אופן",
    "service_name.en": "Tel-o-Fun"
  });
}

server.get('/', function(req, res) {
  return res.redirect('http://itunes.apple.com/us/app/tel-o-bike-tel-aviv-bicycle/id436915919?mt=8');
});

server.get('/stations', get_tlv_stations);
server.get('/tlv/stations', get_tlv_stations);
server.get('/cities/tlv', get_tlv_city);

server.get('/status', function(req, res) {
  return telofun_api(function(err) {
    if (err) {
      res.status(500);
      return res.send({ error: err.message });
    }

    return res.send('Telofun API OK');
  });
});

server.get('/ping', function(req, res) {
  res.send(last_read_status);
});

server.post('/push', function(req, res, next) {
  logging.info('received push token:', req.url);
  return res.send('OK');
});

server.listen(process.env.port || 5000);

logging.info('telobike server started. listening on port ' + (process.env.port || 5000));
