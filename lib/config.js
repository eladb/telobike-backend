var AWS = require('aws-sdk');

exports.AWS_REGION       = process.env.TELOBIKE_AWS_REGION || 'eu-west-1';
exports.CLOUDWATCH_GROUP = process.env.TELOBIKE_CLOUDWATCH_GROUP || 'telobike';
exports.TELOFUN_ENDPOINT = process.env.TELOBIKE_TELOFUN_ENDPOINT || 'http://www.tel-o-fun.co.il:2468/ExternalWS/Geo.asmx?wsdl';
exports.TELOFUN_USER     = process.env.TELOBIKE_TELOFUN_USER;
exports.TELOFUN_PASSWORD = process.env.TELOBIKE_TELOFUN_PASSWORD;

// global AWS region configuration
AWS.config.region = exports.AWS_REGION;

if (!exports.TELOFUN_USER || !exports.TELOFUN_PASSWORD) {
  throw new Error('TELOBIKE_TELOFUN_USER and TELOBIKE_TELOFUN_PASSWORD must be defined as environment variables');
}

console.log('config:')
console.log(Object.keys(exports).map(k => '  ' + k + '=' + exports[k]).join('\n'));
