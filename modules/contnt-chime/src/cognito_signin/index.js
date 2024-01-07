const AWS = require('aws-sdk');

AWS.config.update({ region: process.env.AWS_REGION });

const chimeIdentity = new AWS.ChimeSDKIdentity({ region: process.env.AWS_REGION });

const { CHIME_APP_INSTANCE_ARN } = process.env;

exports.handler = async (event, context, callback) => {
  const username = event.userName;
  // const userId = event.request.userAttributes['custom:cognito_identity_id'];
  // const userId = event.request.userAttributes.profile

  // // 'none' is default user cognito_identity_id attribute in Cognito upon registration which
  // if (userId === 'NA') {
  //   console.log(`User hasn't logged in yet and hasn't been setup with cognito_identity_id`);
  //   callback(null, event);
  //   return;
  // }
  // Create a Chime App Instance User for the user
  const chimeCreateAppInstanceUserParams = {
    AppInstanceArn: CHIME_APP_INSTANCE_ARN,
    AppInstanceUserId: username,
    Name: username
  };

  try {
    console.log(`Creating app instance user for ${username}`);
    const user = await chimeIdentity
      .createAppInstanceUser(chimeCreateAppInstanceUserParams)
      .promise();
  } catch (e) {
    console.log(JSON.stringify(e));
    return {
      statusCode: 500,
      body: e.stack
    };
  }
  // Return to Amazon Cognito
  callback(null, event);
};
