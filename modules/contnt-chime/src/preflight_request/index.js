exports.handler = function(event, context, callback) {
  let origin = 'https://localhost:9000';
  if (event.headers["origin"]?.match(/cloudfront.net$/)) {
      origin = event.headers.origin;
  }
  callback(null, {
    statusCode: 200,
    headers: {
        "Access-Control-Allow-Origin" : origin,
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Methods": "OPTIONS,POST",
        'Access-Control-Allow-Headers': 'Authorization',
    },
  })
}