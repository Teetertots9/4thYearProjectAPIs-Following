###################################
# following-api-authorizer lambda function
###################################

resource "aws_iam_role" "following-api-authorizer-invocation-role" {
  name = "${var.prefix}-following-api-authorizer-invocation-role-${var.stage}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "following-api-authorizer-invocation-policy" {
  name = "${var.prefix}-following-api-authorizer-invocation-policy-${var.stage}"
  role = aws_iam_role.following-api-authorizer-invocation-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.following-api-authorizer.arn}"
    }
  ]
}
EOF
}


# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "following-api-authorizer-role" {
  name = "${var.prefix}-following-api-authorizer-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "following-api-authorizer-policy" {
    name        = "${var.prefix}-following-api-authorizer-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "following-api-authorizer-attach" {
    role       = aws_iam_role.following-api-authorizer-role.name
    policy_arn = aws_iam_policy.following-api-authorizer-policy.arn
}

resource "aws_lambda_function" "following-api-authorizer" {
  function_name = "${var.prefix}-following-api-authorizer-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/api-authorizer.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/api-authorizer.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.following-api-authorizer-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.cognito_user_pool_id
    }
  }
}

###################################
# get-favours lambda function
###################################

resource "aws_lambda_function" "get-following" {
  function_name = "${var.prefix}-get-following-${var.stage}"

  # The zip containing the lambda function
  filename         = "../../../lambda/dist/functions/get.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/get.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.get-following-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region = var.region,
      table  = aws_dynamodb_table.following_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "get-following-role" {
  name = "${var.prefix}-get-following-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get-following-policy" {
  name        = "${var.prefix}-get-following-policy-${var.stage}"
  description = ""
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:Scan"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}"
    },
    {
      "Action": [
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}/index/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get-following-attach" {
  role       = aws_iam_role.get-following-role.name
  policy_arn = aws_iam_policy.get-following-policy.arn
}

resource "aws_lambda_permission" "get-following-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-following.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.following-api.execution_arn}/*/*"
}

###################################
# create-followin function
###################################

resource "aws_lambda_function" "create-followin" {
  function_name = "${var.prefix}-create-followin-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/create.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/create.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.create-followin-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.following_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "create-followin-role" {
  name = "${var.prefix}-create-followin-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "create-followin-policy" {
    name        = "${var.prefix}-create-followin-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:PutItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "create-followin-attach" {
    role       = aws_iam_role.create-followin-role.name
    policy_arn = aws_iam_policy.create-followin-policy.arn
}

resource "aws_lambda_permission" "create-followin-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create-followin.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.following-api.execution_arn}/*/*"
}


###################################
# get-followin-details function
###################################

resource "aws_lambda_function" "get-followin-details" {
  function_name = "${var.prefix}-get-followin-details-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/get-item.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/get-item.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.get-followin-details-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.following_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "get-followin-details-role" {
  name = "${var.prefix}-get-followin-details-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get-followin-details-policy" {
    name        = "${var.prefix}-get-followin-details-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:GetItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get-followin-details-attach" {
    role       = aws_iam_role.get-followin-details-role.name
    policy_arn = aws_iam_policy.get-followin-details-policy.arn
}

resource "aws_lambda_permission" "get-followin-details-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-followin-details.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.following-api.execution_arn}/*/*"
}


###################################
# delete-followin function
###################################

resource "aws_lambda_function" "delete-followin" {
  function_name = "${var.prefix}-delete-followin-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/delete.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/delete.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.delete-followin-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.following_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "delete-followin-role" {
  name = "${var.prefix}-delete-followin-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "delete-followin-policy" {
    name        = "${var.prefix}-delete-followin-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:DeleteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "delete-followin-attach" {
    role       = aws_iam_role.delete-followin-role.name
    policy_arn = aws_iam_policy.delete-followin-policy.arn
}

resource "aws_lambda_permission" "delete-followin-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete-followin.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.following-api.execution_arn}/*/*"
}

###################################
# update-followin function
###################################

resource "aws_lambda_function" "update-followin" {
  function_name = "${var.prefix}-update-followin-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/update.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/update.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.update-followin-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      table = aws_dynamodb_table.following_table.id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "update-followin-role" {
  name = "${var.prefix}-update-followin-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "update-followin-policy" {
    name        = "${var.prefix}-update-followin-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "dynamodb:UpdateItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${aws_dynamodb_table.following_table.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "update-followin-attach" {
    role       = aws_iam_role.update-followin-role.name
    policy_arn = aws_iam_policy.update-followin-policy.arn
}

resource "aws_lambda_permission" "update-followin-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-followin.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.following-api.execution_arn}/*/*"
}