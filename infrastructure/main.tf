# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# S3 --------------------------------------------------------------------------
# S3 static website hosting
resource "aws_s3_bucket" "b" {
  bucket = "thingshared.xyz"
  acl = "public-read"
  policy = "${file("bucketpolicy.json")}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# S3 (private) upload bucket
resource "aws_s3_bucket" "u" {
  bucket = "uploadbucket.thingshared.xyz"
  acl = "authenticated-read"
  tags {
    Name = "Upload Bucket"
  }
}

# DynamoDB --------------------------------------------------------------------
# DynamoDB Table
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name = "HashSums"
  read_capacity = 1
  write_capacity = 1
  hash_key = "Key"
  attribute {
    name = "Key"
    type = "S"
  }
}

# Lambda ----------------------------------------------------------------------
# Lambda Role / Policy
resource "aws_iam_role" "iam_for_lambda" {
    name = "lambda_s3_dynamodb_exec_role"
    assume_role_policy = "${file("lambdapolicy.json")}"
}
resource "aws_iam_role_policy" "policy" {
  name = "lambda_s3_dynamodb_exec_policy"
  role = "${aws_iam_role.iam_for_lambda.id}"
  policy = "${file("lambdapolicy_exec.json")}"
}

# Lambda Upload
resource "aws_lambda_function" "upload_event" {
  filename = "../lambda_functions/upload/Archiv.zip"
  function_name = "upload"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "index.handler"
}

# Upload User Policy
resource "aws_iam_user" "uploaduser" {
    name = "thingshared-upload-user"
}
resource "aws_iam_access_key" "uploaduser" {
    user = "${aws_iam_user.uploaduser.name}"
}
resource "aws_iam_user_policy" "uploaduser_ro" {
    name = "test"
    user = "${aws_iam_user.uploaduser.name}"
    policy = "${file("uploadpolicy.json")}"
}

# S3 to Lambda
# Coming soon
