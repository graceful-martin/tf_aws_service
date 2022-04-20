############################################################
## 영상 업로드용 버킷 생성                                  ##
############################################################

resource "aws_s3_bucket" "inputBucket" {
    bucket = "input-${local.date}-${local.tail}"

    tags = {
        Name = "mp4 input bucket"
    }
}

resource "aws_s3_bucket_acl" "inputBucket_acl" {
    bucket = aws_s3_bucket.inputBucket.id
    acl    = "private"
}

