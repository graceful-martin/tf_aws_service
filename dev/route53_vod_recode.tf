


data "aws_route53_zone" "goormedu-clone" {
  name         = local.domain
}


resource "aws_route53_record" "vod_domain" {
  zone_id = data.aws_route53_zone.goormedu-clone.zone_id
  name    = "vod.${local.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.hlsDistribution.domain_name
    zone_id                = aws_cloudfront_distribution.hlsDistribution.hosted_zone_id
    evaluate_target_health = false
  }
}
