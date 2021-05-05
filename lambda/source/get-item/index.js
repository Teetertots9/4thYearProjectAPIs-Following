
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Get Following Details', level: 'info' });
// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { params } = event;

    const { user_id } = params.path;

    const getItemParams = {
      TableName: TABLE_NAME,
      Key: {
        user_id,
      },
      ConditionExpression: 'attribute_exists(user_id)',
    };

    logger.info('Get Item Params:');
    logger.info(getItemParams);

    // get item
    const response = await docClient.get(getItemParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    } else if (!response.Item) {
      throw new Error('Item not found');
    }

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
