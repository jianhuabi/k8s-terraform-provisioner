locals {
  vpc_id = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"
}

resource "aws_vpc" "konvoy" {
  cidr_block           = "10.0.0.0/16"
  count                = "${var.vpc_id == "" ? 1 : 0}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-vpc"
    )
  )}"
}

resource "aws_internet_gateway" "konvoy_gateway" {
  vpc_id = "${local.vpc_id}"
  count  = "${var.vpc_internet_gateway_id == "" ? (var.create_vpc_internet_gateway ? 1 : 0) : 0}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-gateway"
    )
  )}"
}

resource "aws_default_route_table" "konvoy_router" {
  default_route_table_id = "${var.vpc_route_table_id == "" ? join(",", aws_vpc.konvoy.*.default_route_table_id) : var.vpc_route_table_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-router"
    )
  )}"

  // Routes are added when instances are added
  lifecycle {
    ignore_changes = ["route"]
  }
}

resource "aws_route" "konvoy_gateway_route" {
  count = "${var.create_vpc_internet_gateway ? 1 : 0}"

  route_table_id = "${var.vpc_route_table_id == "" ? join(",", aws_vpc.konvoy.*.default_route_table_id) : var.vpc_route_table_id}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${var.vpc_internet_gateway_id == "" ? join(",", aws_internet_gateway.konvoy_gateway.*.id) : var.vpc_internet_gateway_id}"
}
