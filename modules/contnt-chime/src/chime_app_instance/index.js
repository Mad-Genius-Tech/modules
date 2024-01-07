"use strict"; 
const AWS = require("aws-sdk"); 
const uuidv4 = require("uuid"); 
// const response = require("cfn-response"); 
AWS.config.update({ region: process.env.AWS_REGION });
const chimeIdentity = new AWS.ChimeSDKIdentity({ region: process.env.AWS_REGION }); 
const chimeMessaging = new AWS.ChimeSDKMessaging({ region: process.env.AWS_REGION });
const { PROCESSOR_LAMBDA_ARN, PRESENCE_PROCESSOR_LAMBDA_ARN } = process.env;
const LAMBDA_SERVICE_NAME = process.env.LAMBDA_SERVICE_NAME
async function createChannelFlow(channelFlowParams) {
  await chimeMessaging.createChannelFlow(channelFlowParams, function (err, data) {
    if (err) {
      console.log('Error calling create channel flow');
      console.log(err, err.stack);
    } else {
      console.log(data); // successful
      return data;
    }

  }).promise();
}
exports.handler = async (event, context, callback) => {
  console.log("Event: \n", event);
  console.log("Create Chime SDK App Instance");
  if (event["RequestType"] === "Create") {
    //create a chime app instance
    const params = {
      Name: `${LAMBDA_SERVICE_NAME}-${uuidv4()}`,
    };
    try {
      const appInstance = await chimeIdentity.createAppInstance(
        params,
        function (err, data) {
          if (err) console.log(err, err.stack);
          else {
            console.log(data);
            return data;
          }
        }
      ).promise();

      console.log("Creating channel flow resource for Profanity and DLP Flow");
      await createChannelFlow({
        Name: "Profanity and DLP Flow",
        ClientRequestToken: `CreateChannelFlow-${uuidv4()}`,
        AppInstanceArn: appInstance.AppInstanceArn,
        Processors: [{
          ExecutionOrder: 1,
          Name: "ProfanityAndDLPProcessor",
          FallbackAction: 'ABORT',
          Configuration: {
            Lambda: {
              ResourceArn: PROCESSOR_LAMBDA_ARN,
              InvocationType: 'ASYNC'
            }
          }
        }]
      });

      console.log("Creating channel flow resource for Presence");
      await createChannelFlow({
        Name: "Presence Channel Flow",
        ClientRequestToken: `CreateChannelFlow-${uuidv4()}`,
        AppInstanceArn: appInstance.AppInstanceArn,
        Processors: [{
          ExecutionOrder: 1,
          Name: "PresenceProcessor",
          FallbackAction: 'ABORT',
          Configuration: {
            Lambda: {
              ResourceArn: PRESENCE_PROCESSOR_LAMBDA_ARN,
              InvocationType: 'ASYNC'
            }
          }
        }]
      });

      return appInstance;
      // await response.send(event, context, response.SUCCESS, appInstance);
    } catch (error) {
      console.log("ERROR CAUGHT \n", error);
      return {};
      // await response.send(event, context, response.FAILED, {});
    }
  } else {
    //NOT A CREATE REQUEST
    return {};
    // await response.send(event, context, response.SUCCESS, {});
  }
};
