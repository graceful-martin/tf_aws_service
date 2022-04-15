terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.27"
        }
    }

    required_version = ">= 0.14.9"
}
# 테라폼 버전 설정 등 cmake 파일이랑 비슷한 동작



provider "aws" {
    profile = "default"
    region  = "ap-northeast-2"
}
# 프로바이더 설정, 여기서 프로필은 aws cli에 인증되어있는 계정을 말함
#                                   -> 로컬에 인증되어있는 계정
#                                   
# 지역 변경 가능 (지역 변경이 민감한 리소스 사용시 주의)





resource "aws_s3_bucket" "inputBucket" {
    bucket = "terraform-test-input-${local.date}-${local.tail}"

    tags = {
        Name = "My bucket"
    }
}

resource "aws_s3_bucket_acl" "inputBucket_acl" {
    bucket = aws_s3_bucket.inputBucket.id
    acl    = "private"
}

# 특정 리소스를 만드는 예제, 
# 파라미터들은 문서 참조
#
# ex:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket





resource "aws_s3_bucket" "outputBucket" {
    bucket = "terraform-test-output-${local.date}-${local.tail}"

    tags = {
        Name = "My bucket"
    }
}

resource "aws_s3_bucket_acl" "outputBucket_acl" {
    bucket = aws_s3_bucket.outputBucket.id
    acl    = "private"
}


resource "aws_s3_bucket_cors_configuration" "outputBucket_cors" {
    bucket = aws_s3_bucket.outputBucket.bucket

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT", "POST", "GET"]
        allowed_origins = ["*"]
        expose_headers = []
        max_age_seconds = 3000
    }
}
# 대시보드에서 리소스를 생성할때 입력한 것들은 모두 넣을수있다
# 출력 버킷의 경우 CORS 체크가 필요하기떄문에 해당 설정을 넣어준 것인데
# 주의할점은 문서의 s3_bucket 항목에 같이 있지 않고 독립되어 있다는 것 이다.
#
# ex:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration
# (위쪽 url과 다름)








locals {
    s3_origin_id = "outputBucketOrigin"
    date = "220412"
    tail = "02"
}

resource "aws_cloudfront_origin_access_identity" "example_OAI" {
    comment = "Some comment"
}
#   원본 액세스 아이디




resource "aws_cloudfront_distribution" "s3_distribution" {
    origin {
        domain_name = aws_s3_bucket.outputBucket.bucket_regional_domain_name
        origin_id   = local.s3_origin_id

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.example_OAI.cloudfront_access_identity_path
        }
    }  

    enabled             = true

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    # Cache behavior with precedence 0
    ordered_cache_behavior {
        path_pattern     = "*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = local.s3_origin_id

        forwarded_values {
            query_string = false
            headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

            cookies {
                forward = "none"
            }
        }

        min_ttl                = 0
        default_ttl            = 86400
        max_ttl                = 31536000
        compress               = true
        viewer_protocol_policy = "redirect-to-https" # 이 값이 명시되어있지 않음, 기본값 이용
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }


    viewer_certificate {
        cloudfront_default_certificate = true
    }
}
#   위에서 만든 원본 액세스 아이디를
#   cloudfront에서 쓸수있게함








resource "aws_s3_bucket_policy" "allow_access_from_cloudfront_account" {
    bucket = aws_s3_bucket.outputBucket.id
    policy = data.aws_iam_policy_document.allow_access_from_cloudfront_account.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront_account" {
    statement {
        sid = "1"

        principals {
            type        = "AWS"
            identifiers = [aws_cloudfront_origin_access_identity.example_OAI.iam_arn]
        }

        actions = ["s3:GetObject", ]
        effect = "Allow"

        resources = ["${aws_s3_bucket.outputBucket.arn}/*",]
    }
}

# 이 부분은 S3 를 먼저 만들고 
#   -> 원본 접근 ID를 만들고
#   -> CloudFront에서 생성한 S3의 원본을 접근하는 배포를 만들고 (원본 액세스 아이디 이용)
#   -> 해당 원본 액세스 아이디에 대하여 접근가능 정책을 만들어 줘야 하기 때문에 순서상 아래쪽





resource "aws_iam_policy" "bucket_access_policy" {
    name        = "test_policy_${local.date}-${local.tail}"
    description = "test"

    policy = data.aws_iam_policy_document.bucket_access_policy_json.json
}

data "aws_iam_policy_document" "bucket_access_policy_json" {

    statement {
        actions   = ["s3:*"]
        resources = [aws_s3_bucket.outputBucket.arn]
        effect = "Allow"
    }
}










resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda_${local.date}-${local.tail}"

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

resource "aws_iam_policy" "iam_for_lambda_policy1" {
  name        = "test-iam_for_lambda_policy1${local.date}-${local.tail}"
  description = "A test policy"

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
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "${aws_iam_role.iam_for_media_convert.arn}"
            ],
            "Effect": "Allow",
            "Sid": "PassRole"
        },
        {
            "Action": [
                "mediaconvert:*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "MediaConvertService"
        },
        {
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "S3Service"
        }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda_policy1-attachment" {
    role = "${aws_iam_role.iam_for_lambda.name}"
    policy_arn = aws_iam_policy.iam_for_lambda_policy1.arn
}



resource "aws_iam_policy" "iam_for_lambda_policy2" {
  name        = "test-iam_for_lambda_policy2_${local.date}-${local.tail}"
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
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "lambda.amazonaws.com"
                }
            }
        },
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

resource "aws_iam_role_policy_attachment" "iam_for_lambda_policy2-attachment" {
    role = "${aws_iam_role.iam_for_lambda.name}"
    policy_arn = aws_iam_policy.iam_for_lambda_policy2.arn
}










data "aws_iam_policy_document" "lambda_execute_policy_json" {
    version = "2012-10-17"

    statement {
        actions = [ "sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers  = ["lambda.amazonaws.com"]
        }
        effect = "Allow"
    }
}






resource "aws_iam_role" "iam_for_media_convert" {
    name = "iam_for_media_convert_${local.date}-${local.tail}"

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









resource "aws_lambda_function" "test_lambda" {
  filename      = "src.zip"
  function_name = "mediaConvertLambda_${local.date}-${local.tail}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "convert.handler"

  runtime = "python3.8"

  environment {
    variables = {
      Application = "VOD"
      DestinationBucket = aws_s3_bucket.outputBucket.id
      MediaConvertRole = aws_iam_role.iam_for_media_convert.arn
    }
  }
}

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.inputBucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*"]

  }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.inputBucket.id}"
}




resource "aws_iam_role_policy" "media_convert_policy" {
    name = "media_convert_policy_${local.date}-${local.tail}"
    role = aws_iam_role.iam_for_media_convert.id
    
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