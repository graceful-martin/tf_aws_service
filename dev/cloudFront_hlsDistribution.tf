############################################################
## output 버킷 접근용 OAI를 이용하는 cloudFront 배포 생성    ##
############################################################


resource "aws_cloudfront_distribution" "hlsDistribution" {

    origin {
        domain_name = aws_s3_bucket.outputBucket.bucket_regional_domain_name
        origin_id   = "s3_output_origin"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.s3_output_OAI.cloudfront_access_identity_path
        }
    }  

    enabled             = true
    aliases             = ["vod.${local.domain}"]

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "s3_output_origin"

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

    ordered_cache_behavior {
        path_pattern     = "*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = "s3_output_origin"

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
        viewer_protocol_policy = "redirect-to-https"
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }


    viewer_certificate {
        cloudfront_default_certificate  = false
        acm_certificate_arn              = data.aws_acm_certificate.SSL_certificate.arn
        minimum_protocol_version        = "TLSv1.2_2021"
        ssl_support_method              = "sni-only"
    }

}

provider "aws"{
  alias = "virginia"
  region = "us-east-1"
}

data "aws_acm_certificate" "SSL_certificate" {
  domain   = "*.${local.domain}"
  provider = aws.virginia
}






