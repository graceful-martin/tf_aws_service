############################################################
## media_convert 를 실행시켜줄 role 정의                    ##
############################################################

resource "aws_iam_role" "mediaConvertRole" {
    name = "mediaConvertRole_${local.date}-${local.tail}"

    assume_role_policy =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "mediaconvert.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "media_convert_policy" {
    name = "media_convert_policy_${local.date}-${local.tail}"
    role = aws_iam_role.mediaConvertRole.id
    
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:Invoke",
                "execute-api:ManageConnections"
            ],
            "Resource": "arn:aws:execute-api:*:*:*"
        }
    ]
}
EOF
}