############################################################
## 커스텀한 정책들,,,                                      ##
############################################################


resource "aws_iam_policy" "bucket_access_policy" {
    name        = "bucketFullAccess_${local.date}-${local.tail}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    
        {
            "Action": [
                "s3:*"
            ],
            "Resource": "${aws_s3_bucket.outputBucket.arn}",
            "Effect": "Allow",
            "Sid": "allowOutputBucketAccess"
        }
  ]
}
EOF
}

resource "aws_iam_policy" "api_invoke_policy" {
  name        = "api_invoke_policy_${local.date}-${local.tail}"
  description = "A test policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStacks",
                "cloudformation:ListStackResources",
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricData",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "kms:ListAliases",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:ListRoles",
                "lambda:*",
                "logs:DescribeLogGroups",
                "states:DescribeStateMachine",
                "states:ListStateMachines",
                "tag:GetResources",
                "xray:GetTraceSummaries",
                "xray:BatchGetTraces"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}




resource "aws_iam_policy" "pass_lambdaRole_poilcy" {
  name        = "pass_lambdaRole_poilcy_${local.date}-${local.tail}"
  description = "for call lambdaRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "lambda.amazonaws.com"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "get_lambda_event_policy" {
  name        = "get_lambda_event_policy_${local.date}-${local.tail}"
  description = "get lambda event from log event"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogStreams",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/*"
        }
    ]
}
EOF
}









resource "aws_iam_policy" "logging_policy" {
  name        = "logging_policy_${local.date}-${local.tail}"
  description = "policy for logging"

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
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "Logging"
        }
  ]
}
EOF
}

resource "aws_iam_policy" "pass_mediaConvertRole_poilcy" {
  name        = "pass_mediaConvertRole_poilcy_${local.date}-${local.tail}"
  description = "for call mediaConvertRole"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "${aws_iam_role.mediaConvertRole.arn}"
            ],
            "Effect": "Allow",
            "Sid": "PassRole"
        }
  ]
}
EOF
}

resource "aws_iam_policy" "run_mediaConvert_poilcy" {
  name        = "run_mediaConvert_poilcy_${local.date}-${local.tail}"
  description = "for run mediaConvert service"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": [
                "mediaconvert:*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "MediaConvertService"
        }
  ]
}
EOF
}
  


