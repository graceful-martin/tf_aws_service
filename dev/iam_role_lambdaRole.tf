############################################################
## lambda 를 실행시켜줄 role 정의                          ##
############################################################

resource "aws_iam_role" "lambdaRole" {
    name = "lambdaRole_${local.date}-${local.tail}"

    assume_role_policy =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}



resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment1" {


    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.bucket_access_policy.arn
}


resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment2" {


    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.api_invoke_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment3" {

    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.pass_lambdaRole_poilcy.arn
}

resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment4" {


    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.get_lambda_event_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment5" {


    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment6" {

    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.pass_mediaConvertRole_poilcy.arn
}

resource "aws_iam_role_policy_attachment" "lambdaRole_policy-attachment7" {

    role = "${aws_iam_role.lambdaRole.name}"
    policy_arn = aws_iam_policy.run_mediaConvert_poilcy.arn
}
