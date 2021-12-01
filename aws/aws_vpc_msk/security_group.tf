resource "aws_security_group" "KafkaClusterSG" {
  name        = "msk-${lower(var.environment)}-sg-${random_uuid.randuuid.result}"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.msk_vpc.id

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common-tags,
    map(
      "Name", "msk-${lower(var.environment)}-sg-${random_uuid.randuuid.result}"
    )
    , {
      yor_trace = "f512aa4b-01ae-49f3-99ce-e163946b86df"
  })
}

resource "aws_security_group" "KafkaClientInstanceSG" {
  name        = "KafkaClientInstanceSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.msk_vpc.id

  ingress {
    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common-tags,
    map(
      "Name", "KafkaClientInstanceSG"
    )
    , {
      yor_trace = "719194e5-9490-4cad-b819-1a01cb8b3881"
  })
}