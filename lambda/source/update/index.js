
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Update Following', level: 'info' });
// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { params, body } = event;
    const { user_id } = params.path;

    let updateString = '';
    const keyValueMapping = {};


    Object.keys(body).forEach((key) => {
      updateString += ` ${key} = :${key},`;
      keyValueMapping[`:${key}`] = event.body[key];
    });
    // remove last comma
    updateString = updateString.slice(0, -1);

    const updateItemParams = {
      TableName: TABLE_NAME,
      Key: {
        user_id,
      },
      UpdateExpression: `set ${updateString}`,
      ExpressionAttributeValues: keyValueMapping,
      ReturnValues: 'UPDATED_NEW',
    };

    // update item
    const response = await docClient.update(updateItemParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    }

    response.user_id = user_id;
    response.Message = 'Item Updated Succesfully';

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
