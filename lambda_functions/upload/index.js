var crypto  = require('crypto');
var AWS     = require('aws-sdk');
var doc     = require('dynamodb-doc');
var dynamo  = new doc.DynamoDB();
var s3      = new AWS.S3();

exports.handler = function(event, context) {
  console.log('Received event:', JSON.stringify(event, null, 2));

  s3.getObject({
    Bucket: event.Records[0].s3.bucket.name,
    Key: event.Records[0].s3.object.key
  },function (err, response) {
    if (err) {
      return context.fail(err)
    }
    console.log('calculate hash sum')

    var hash = crypto
    .createHash('md5')
    .update(response.Body)
    .digest('hex')

    console.log('hash LAMBDA:', hash)

    var params = {};
    params.TableName = "HashSums";
    params.Item = {
      Hash: hash,
      Date: Date(),
      Key: event.Records[0].s3.object.key
    }

    dynamo.putItem(params, function (err, data) {
      if (err) { return context.fail(err) }
      context.succeed(hash)
    });
  })
}
