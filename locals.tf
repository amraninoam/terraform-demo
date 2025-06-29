locals {
  az1 = data.aws_availability_zones.azs.names[0]
  az2 = data.aws_availability_zones.azs.names[1]
}