resource "aws_vpc_endpoint" "ec2" {
  count = "${var.create_vpc_endpoints ? 1 : 0}"

  vpc_id            = "${aws_vpc.konvoy.id}"
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.konvoy_private.id}",
  ]

  # there is currently aws_security_group.konvoy_private that allows ingress/egress access within the SG
  # this SG is added to all worker and control-plane pools
  # this CSI driver pod will be running on one of the workers and will have access to this VPC endpoint in the control-plane subent
  subnet_ids = [
    "${local.control_plane_subnet_ids}",
  ]

  private_dns_enabled = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-vpc-endpoint-ec2"
    )
  )}"
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  count = "${var.create_vpc_endpoints ? 1 : 0}"

  vpc_id            = "${aws_vpc.konvoy.id}"
  service_name      = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.konvoy_private.id}",
  ]

  # use the control-plane subnets since the kube-apiserver and the kube-controller-manager will be the ones accessing the endpoint
  subnet_ids = [
    "${local.control_plane_subnet_ids}",
  ]

  private_dns_enabled = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-vpc-endpoint-elasticloadbalancing"
    )
  )}"
}
