module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "${var.prefix}-${var.environment}"
  cidr                   = var.vpc_cidr
  azs                    = data.aws_availability_zones.this.names
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  tags = merge(var.tags, {
    yor_trace = "23dc9abd-f442-46f7-8449-8fc00e83ff8c"
  })
  version              = "~>2.0"
  enable_dns_hostnames = true
}
