data "aws_availability_zones" "available" {}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.msk_vpc.id
  cidr_block        = element(split(",", join(",", var.private_subnet_cidrs)), count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common-tags,
    map(
      "Name", "MSK-${lower(var.environment)}-private-subnet-${count.index + 1}",
      "Description", "${lower(var.environment)} private subnet - ${count.index + 1}"
    )
    , {
      yor_trace = "f971afae-be21-4675-8fb1-d0c70b3c3d23"
  })

}



resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.msk_vpc.id
  cidr_block        = element(split(",", join(",", var.public_subnet_cidrs)), count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common-tags,
    map(
      "Name", "msk-${lower(var.environment)}-public-subnet-${count.index + 1}",
      "Description", "${lower(var.environment)} private subnet - ${count.index + 1}"
    )
    , {
      yor_trace = "123a2409-e434-4572-a7db-a552305f2db7"
  })

}
