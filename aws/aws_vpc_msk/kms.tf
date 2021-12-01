resource "aws_kms_key" "pca-kms" {
  description         = "KMS Key for encrypting the PCA s3 bucket"
  enable_key_rotation = "true"
  policy              = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-policy-with-replication",
    "Statement": [
          {
            "Sid": "Account usage of KMS Key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
      ]
}
EOF
  tags = {
    yor_trace = "7e3aad08-23d6-455f-904b-8cec77d71b5f"
  }
}

resource "aws_kms_alias" "pca-kims-alias" {
  name          = "alias/pca-kims-alias"
  target_key_id = aws_kms_key.pca-kms.key_id
}

resource "random_id" "kms" {
  byte_length = 2
}
resource "aws_kms_key" "msk-kms-key" {
  description         = "KMS Key for encrypting the EBS volumes"
  enable_key_rotation = "true"
  policy              = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-policy-with-replication",
    "Statement": [
          {
            "Sid": "Account usage of KMS Key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
      ]
}
EOF
  tags = {
    yor_trace = "f6d36b57-9f85-405c-bd32-bd324aae76ea"
  }
}

resource "aws_kms_alias" "msk-kms-alias" {
  name          = "alias/msk-kms-alias-${random_id.kms.hex}"
  target_key_id = aws_kms_key.msk-kms-key.key_id
}
