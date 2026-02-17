resource "aws_s3_bucket" "avatars" {
  bucket_prefix = "${var.project_name}-avatars"

  tags = {
    Name        = "${var.project_name}-avatars"
    Environment = "Dev"
  }
}
# This resource block ensures that the S3 bucket is not publicly accessible, which is a crucial security measure to protect the data stored in the bucket. By blocking public ACLs and policies, and restricting public bucket access, we can prevent unauthorized access to the avatars stored in the S3 bucket.
resource "aws_s3_bucket_public_access_block" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1: The Policy
resource "aws_iam_policy" "s3_avatar_access_policy" {
  name = "${var.project_name}-s3-avatar-access-policy"
  description = "permissions to access the S3 bucket for avatars"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"

        ],
        Effect   = "Allow",
        Resource = [
          "${aws_s3_bucket.avatars.arn}/*",
          "${aws_s3_bucket.avatars.arn}"
        ]

      }
    ]
  })
  
}

#  2: The Role
resource "aws_iam_role" "ec2_s3_role" {
  name = "${var.project_name}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com" # Allows EC2 to use it
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-iam-role"
  }
}

#  3: Attachment
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_avatar_access_policy.arn   #arn:aws:iam::aws:policy/AmazonS3FullAccess Look at this.
}   

# 4: Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}

