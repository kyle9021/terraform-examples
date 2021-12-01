resource "aws_iam_instance_profile" "KafkaClientIAM_Profile" {
  name = "KafkaClientIAM_profile"
  role = aws_iam_role.KafkaClientIAM_Role.name
  tags = {
    yor_trace = "e32ba3e2-1231-46be-8fec-86c6df686ef2"
  }
}

resource "aws_iam_role" "KafkaClientIAM_Role" {
  name = "KafkaClientIAM_Role"
  path = "/"


  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags = {
    yor_trace = "d31c5a83-b264-498f-9a65-a74732e00839"
  }
}

resource "aws_iam_role_policy_attachment" "Kafka-Client-IAM-role-att1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
  role       = aws_iam_role.KafkaClientIAM_Role.name
}

resource "aws_iam_role_policy_attachment" "Kafka-Client-IAM-role-att2" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
  role       = aws_iam_role.KafkaClientIAM_Role.name
}

resource "aws_instance" "Kafka-Client-EC2-Instance" {
  ami                    = var.msk_ami
  instance_type          = var.msk_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.KafkaClientInstanceSG.id]
  user_data              = file("./kafka-client-msk.sh")
  subnet_id              = aws_subnet.private_subnet[1].id
  iam_instance_profile   = aws_iam_instance_profile.KafkaClientIAM_Profile.name
  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = 100
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.msk-kms-key.arn
  }

  tags = merge(
    local.common-tags,
    map(
      "Name", "Kafka-Client-EC2-Instance"
    )
    , {
      yor_trace = "14ee9648-cbdd-404a-adf4-9e49d0801df8"
  })
}

output "IP" {
  value       = aws_instance.Kafka-Client-EC2-Instance.private_ip
  description = "The private IP address of the Kafka-Client-EC2-Instance instance."
}
