variable "TWILIO_ACCOUNT_SID" {}
variable "TWILIO_ACCOUNT_AUTH_TOKEN" {}
variable "TWILIO_NUMBER" {}
variable "PAGER_NUMBER" {}
variable "SLACK_TOKEN" {}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
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

resource "aws_api_gateway_rest_api" "pager" {
  name        = "Pager API"
  description = "Slack to SMS gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.pager.id}"
  parent_id   = "${aws_api_gateway_rest_api.pager.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.pager.id}"
  resource_id   = "${aws_api_gateway_rest_api.pager.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.pager.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.pager.invoke_arn}"
}


resource "aws_api_gateway_deployment" "pager" {
  depends_on = [
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.pager.id}"
  stage_name  = "prd"
}


resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.pager.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.pager.invoke_arn}"
}



resource "aws_lambda_function" "pager" {
    function_name = "pager"
    handler = "pager"
    runtime = "go1.x"
    filename = "../main.zip"
    source_code_hash = "${base64sha256(file("../main.zip"))}"
    role = "${aws_iam_role.lambda_exec_role.arn}"
    environment {
        variables = {
            TWILIO_ACCOUNT_SID = "${var.TWILIO_ACCOUNT_SID}"
            TWILIO_ACCOUNT_AUTH_TOKEN = "${var.TWILIO_ACCOUNT_AUTH_TOKEN}"
            TWILIO_NUMBER = "${var.TWILIO_NUMBER}"
            PAGER_NUMBER = "${var.PAGER_NUMBER}"
            SLACK_TOKEN = "${var.SLACK_TOKEN}"
        }
    }
}
