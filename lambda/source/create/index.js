
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
// Set the region
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Create Following', level: 'info' });
// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { body } = event;

    const item = {
      user_id : body.username,
      user_followers: [],
      ...body,
    };

    const createItemParams = {
      TableName: TABLE_NAME,
      Item: item,
      ConditionExpression: 'attribute_not_exists(user_id)',
    };

    logger.info('Create Item Params:');
    logger.info(createItemParams);

    // create item
    const response = await docClient.put(createItemParams).promise();

    if (response.errorMessage) {
      throw new Error(response.errorMessage);
    }

    response.Item = createItemParams.Item;
    response.Message = 'Item Created Succesfully';

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
