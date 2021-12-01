######## IGW ###############
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.msk_vpc.id
  tags = merge(
    local.common-tags,
    map(
      "Name", "MSK-IGW",
      "Description", "Internet Gateway"
    )
    , {
      yor_trace = "e3f5a70a-7af2-4eff-8177-6aaa78aad5ff"
  })
}

########### NAT ##############
resource "aws_eip" "nat" {
  tags = {
    yor_trace = "1e6d7401-47b3-4afd-96ca-eec9e2808e46"
  }
}

resource "aws_nat_gateway" "main-natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = merge(
    local.common-tags,
    map(
      "Name", "MSK-NatGateway",
      "Description", "NAT Gateway"
    )
    , {
      yor_trace = "96e14369-f6dc-42b7-8f0f-1694967c5342"
  })
}

############# Route Tables ##########

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.msk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  tags = merge(
    local.common-tags,
    map(
      "Name", "MSK-Public-Routetable",
      "Description", "Public-Routetable"
    )
    , {
      yor_trace = "bd9e6dac-683d-4312-8a1b-21ba11a6294b"
  })

}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.msk_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main-natgw.id
  }
  tags = merge(
    local.common-tags,
    map(
      "Name", "MSK-Private-Routetable",
      "Description", "Private-Routetable"
    )
    , {
      yor_trace = "d5b7fa2b-edef-4b95-ac30-a59517d4f874"
  })
}

#########Route Table Association #############

resource "aws_route_table_association" "route_Publicsubnet" {
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  count          = length(var.public_subnet_cidrs)
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "route_Privatesubnet" {
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  count          = length(var.private_subnet_cidrs)
  route_table_id = aws_route_table.PrivateRouteTable.id
}
