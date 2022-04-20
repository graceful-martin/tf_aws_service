############################################################
## 출력용 영상 업로드 버킷, OAI 생성, cors, 접근 권한 설정   ##
############################################################

resource "aws_s3_bucket" "outputBucket" {
    bucket = "output-${local.date}-${local.tail}"

    tags = {
        Name = "hls output bucket"
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


resource "aws_cloudfront_origin_access_identity" "s3_output_OAI" {
    comment = "orign access id for hls output bucket"
}


resource "aws_s3_bucket_policy" "allow_access_from_cloudfront_account" {
    bucket = aws_s3_bucket.outputBucket.id
    policy = data.aws_iam_policy_document.allow_access_from_cloudfront_account.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront_account" {
    statement {
        sid = "1"

        principals {
            type        = "AWS"
            identifiers = [aws_cloudfront_origin_access_identity.s3_output_OAI.iam_arn]
        }

        actions = ["s3:GetObject", ]
        effect = "Allow"

        resources = ["${aws_s3_bucket.outputBucket.arn}/*",]
    }
}




















