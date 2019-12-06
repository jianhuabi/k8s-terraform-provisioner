locals {
  public_subnet_range        = "10.0.64.0/18"
  private_subnet_range       = "10.0.128.0/18"
  control_plane_subnet_range = "10.0.192.0/18"
}

resource "aws_subnet" "konvoy_public" {
  vpc_id                  = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"
  cidr_block              = "${cidrsubnet(local.public_subnet_range, 4, count.index)}"
  map_public_ip_on_launch = "True"
  count                   = "${length(var.public_subnet_ids) == 0 ? length(var.aws_availability_zones) : 0}"
  availability_zone       = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-subnet-public",
      "konvoy/subnet", "public"
    )
  )}"
}

resource "aws_subnet" "konvoy_private" {
  vpc_id            = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"
  cidr_block        = "${cidrsubnet(local.private_subnet_range, 4, count.index)}"
  count             = "${var.create_private_subnets ? length(var.aws_availability_zones) : 0}"
  availability_zone = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-subnet-private",
      "konvoy/subnet", "private"
    )
  )}"
}

resource "aws_subnet" "konvoy_control_plane" {
  vpc_id            = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"
  cidr_block        = "${cidrsubnet(local.control_plane_subnet_range, 4, count.index)}"
  count             = "${length(var.control_plane_subnet_ids) == 0 ? length(var.aws_availability_zones) : 0}"
  availability_zone = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-subnet-control-plane",
      "konvoy/subnet", "control_plane",
      "kubernetes.io/role/elb", 1
    )
  )}"
}
