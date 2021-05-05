
// Load the SDK for JavaScript
const AWS = require('aws-sdk');
const logger = require('pino')({ name: 'Get Following', level: 'info' });
// Set the region
AWS.config.update({ region: process.env.region });

// Create DynamoDB document client
const docClient = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const TABLE_NAME = process.env.table;

exports.handler = async (event) => {
  try {
    logger.info(event);
    const { params } = event;

    const exclusiveStartKey = params.querystring.lastEvaluatedKey;
    const { artistSearchName } = params.querystring;
    const { venueSearchName } = params.querystring;

    let filterString = '';
    const keyValueMapping = {};

    if (artistSearchName) {
      filterString += ' contains(artistSearchName, :artist) and ';
      keyValueMapping[':artist'] = decodeURIComponent(artistSearchName).toLowerCase();
    }
    if (venueSearchName) {
        filterString += ' contains(venueSearchName, :venue) and ';
      keyValueMapping[':venue'] = decodeURIComponent(venueSearchName).toLowerCase();
    }

    filterString = filterString.slice(0, -4);

    const getAllParams = {
      TableName: TABLE_NAME,
    };

    if (exclusiveStartKey) {
      getAllParams.ExclusiveStartKey = {
        favoursId: exclusiveStartKey,
      };
    }

    if (filterString && filterString !== '') {
      getAllParams.FilterExpression = filterString;
    }

    if (Object.keys(keyValueMapping).length > 0) {
      getAllParams.ExpressionAttributeValues = keyValueMapping;
    }


    logger.info('Get All Params:');
    logger.info(getAllParams);

    const response = await docClient.scan(getAllParams).promise();

    if (response.errorMessage) {
      logger.error(response.errorMessage);
      throw new Error(response.errorMessage);
    }

    logger.info(response);

    return response;
  } catch (err) {
    logger.error(err);
    return err;
  }
};
