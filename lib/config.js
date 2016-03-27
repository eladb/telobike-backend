var AWS = require('aws-sdk');

exports.AWS_REGION       = process.env.TELOBIKE_AWS_REGION || 'eu-west-1';
exports.S3_BUCKET        = process.env.TELOBIKE_S3_BUCKET  || 'telobike';
exports.CLOUDWATCH_GROUP = process.env.TELOBIKE_CLOUDWATCH_GROUP || 'telobike';

// global AWS region configuration
AWS.config.region = exports.AWS_REGION;

console.log('config:')
console.log(Object.keys(exports).map(k => '  ' + k + '=' + exports[k]).join('\n'));
