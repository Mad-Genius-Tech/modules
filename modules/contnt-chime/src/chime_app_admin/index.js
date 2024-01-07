"use strict"; 
const AWS = require("aws-sdk"); 
const uuidv4 = require("uuid"); 
// const response = require("cfn-response"); 
AWS.config.update({ region: process.env.AWS_REGION });
const chimeIdentity = new AWS.ChimeSDKIdentity({ region: process.env.AWS_REGION });
const { CHIME_APP_INSTANCE_ARN } = process.env;
exports.handler = async (event, context, callback) => {
  console.log("Event: \n", event);
  console.log("Create Chime SDK App Admin");
  if (event["RequestType"] === "Create") {
    //create a chime app user
    const createUserParams = {
      AppInstanceArn: CHIME_APP_INSTANCE_ARN,
      AppInstanceUserId: `Admin`,
      ClientRequestToken: `${uuidv4()}`,
      Name: `Admin`
    };

    try {
      const userResponse = await chimeIdentity.createAppInstanceUser(createUserParams).promise();

      console.log("Successfully created user");
      console.log(userResponse); // successful
    } catch (error) {
      console.log("ERROR CAUGHT \n", error);
    }

    //create a chime app admin
    const createAdminParams = {
      AppInstanceArn: CHIME_APP_INSTANCE_ARN,
      AppInstanceAdminArn: CHIME_APP_INSTANCE_ARN + '/user/Admin'
    };

    try {
      const adminResponse = await chimeIdentity.createAppInstanceAdmin(createAdminParams).promise();

      console.log("Successfully created user");
      console.log(adminResponse); // successful
      // await response.send(event, context, response.SUCCESS, adminResponse);
      return adminResponse;
    } catch (error) {
      console.log("ERROR CAUGHT \n", error);
      // await response.send(event, context, response.FAILED, {});
      return {};
    }
  } else if (event["RequestType"] === "Delete") {
                // NOOP as app instance deletion will clean users/admins
                // await response.send(event, context, response.SUCCESS, {});
                return {};

  } else {
    // NOT A CREATE or DELETE REQUEST
    // TODO modify??
    // await response.send(event, context, response.FAILED, {});
    return {};
  }
};
