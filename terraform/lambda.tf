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