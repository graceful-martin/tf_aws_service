############################################################
## lambda 함수 정의 및 role 연결, 트리거 설정               ##
############################################################




resource "aws_lambda_function" "convertLambda" {
  filename      = "src.zip"
  function_name = "mediaConvertLambda_${local.date}-${local.tail}"
  role          = aws_iam_role.lambdaRole.arn
  handler       = "convert.handler" 

  runtime = "python3.8"

  environment {
    variables = {
      Application = "VOD"
      DestinationBucket = aws_s3_bucket.outputBucket.id
      MediaConvertRole = aws_iam_role.mediaConvertRole.arn
    }
  }
}



resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.inputBucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.convertLambda.arn
    events              = ["s3:ObjectCreated:*"]

  }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convertLambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.inputBucket.id}"
}

















