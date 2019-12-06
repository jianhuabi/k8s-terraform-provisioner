locals {
  provided_private_subnet_ids = "${distinct(concat(var.worker_pool0_subnet_ids, var.worker_pool1_subnet_ids, var.worker_pool2_subnet_ids, var.worker_pool3_subnet_ids, var.worker_pool4_subnet_ids, var.worker_pool5_subnet_ids, var.worker_pool6_subnet_ids, var.worker_pool7_subnet_ids, var.worker_pool8_subnet_ids, var.worker_pool9_subnet_ids)) }"

  # count cannot be computed from a resource being created, cannot use aws_subnet.konvoy_private.*.id but instead must rely on a concrete value of var.aws_availability_zones
  private_subnet_ids_count = "${var.create_private_subnets ? (length(var.aws_availability_zones) + length(local.provided_private_subnet_ids)) : length(local.provided_private_subnet_ids)}"
  private_subnet_ids       = "${split(",", var.create_private_subnets ? join(",", concat(aws_subnet.konvoy_private.*.id, local.provided_private_subnet_ids)) : join(",", local.provided_private_subnet_ids))}"
}

resource "aws_eip" "nat_ip" {
  count = "${var.bastion_pool_count > 0 ? length(var.aws_availability_zones) : 0}"

  vpc        = true
  depends_on = ["aws_internet_gateway.konvoy_gateway"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-nat-ip"
    )
  )}"
}

resource "aws_nat_gateway" "konvoy_nat_gateway" {
  count = "${var.bastion_pool_count > 0 ? length(var.aws_availability_zones) : 0}"

  allocation_id = "${element(aws_eip.nat_ip.*.id, count.index)}"
  subnet_id     = "${element(local.public_subnet_ids, count.index % length(local.public_subnet_ids))}"

  depends_on = ["aws_internet_gateway.konvoy_gateway"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-nat-gateway"
    )
  )}"
}

resource "aws_route_table" "konvoy_nat_route_table" {
  count = "${var.bastion_pool_count > 0 ? length(var.aws_availability_zones) : 0}"

  vpc_id = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.konvoy_nat_gateway.*.id, count.index)}"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-nat-route-table"
    )
  )}"
}

resource "aws_route_table_association" "konvoy_nat_private" {
  count = "${var.bastion_pool_count > 0 ? local.private_subnet_ids_count : 0}"

  subnet_id      = "${element(local.private_subnet_ids, count.index)}"
  route_table_id = "${element(aws_route_table.konvoy_nat_route_table.*.id, count.index)}"
}

resource "aws_route_table_association" "konvoy_nat_control_plane" {
  count = "${var.bastion_pool_count > 0 ? length(var.aws_availability_zones) : 0}"

  subnet_id      = "${element(local.control_plane_subnet_ids, count.index % length(local.control_plane_subnet_ids))}"
  route_table_id = "${element(aws_route_table.konvoy_nat_route_table.*.id, count.index)}"
}
