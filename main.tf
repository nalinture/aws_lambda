terraform {
      backend "remote" {
         # The name of your Terraform Cloud organization.
         organization = "aws_lambda"

         # The name of the Terraform Cloud workspace to store Terraform state files in.
         workspaces {
           name = "terraform_tutorial"
         }
     }


 required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.74.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #access_key = "AKIAYJ5URY7DEC4Y7T22"
  #secret_key = "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"
}

resource "aws_iam_role" "lambda_role" {
 name   = "terraform_aws_lambda_role"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "sts:AssumeRole",
          "iam:CreateRole"
      ],
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Resource": "arn:aws:iam::571072432070:user/tf_user",
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/hello-python.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_func" {
 filename                       = "${path.module}/python/hello-python.zip"
 function_name                  = "Tuesday-Tech-Talks"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "hello-python.lambda_handler"
 runtime                        = "python3.8"
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

resource "aws_lambda_invocation" "invoke_t3" {
  function_name = aws_lambda_function.terraform_lambda_func.function_name

  input = jsonencode({
    key1 = "DevOps"
    key2 = "accenture"
  })
}

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.invoke_t3.result)
}


output "teraform_aws_role_output" {
 value = aws_iam_role.lambda_role.name
}

output "teraform_aws_role_arn_output" {
 value = aws_iam_role.lambda_role.arn
}

output "teraform_logging_arn_output" {
 value = aws_iam_policy.iam_policy_for_lambda.arn
}
