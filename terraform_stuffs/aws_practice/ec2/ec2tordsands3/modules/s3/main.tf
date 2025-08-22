resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = var.ec2_role_arn
        }
        Action    = [
          "s3:GetObject",   
          "s3:PutObject",   
          "s3:ListBucket"   
        ]
        Resource  = [
          "${aws_s3_bucket.bucket.arn}/*",       
          "${aws_s3_bucket.bucket.arn}"          
        ]
      }
    ]
  })
  depends_on = [ aws_s3_bucket.bucket ]
}


