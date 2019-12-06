locals {
  sg_ssh_name           = "${local.cluster_name}-sg-ssh"
  sg_egress_name        = "${local.cluster_name}-sg-egress"
  sg_private_name       = "${local.cluster_name}-sg-private"
  sg_control_plane_name = "${local.cluster_name}-sg-lb-control"
}

resource "aws_security_group" "konvoy_ssh" {
  name        = "${local.sg_ssh_name}"
  description = "Allow inbound SSH for Konvoy."
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr_blocks}"]
  }

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-securitygroup-ssh",
      "konvoy/securityGroup", "ssh"
    )
  )}"
}

resource "aws_security_group" "konvoy_private" {
  name        = "${local.sg_private_name}"
  description = "Allow all communication between nodes."
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = "True"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = "True"
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-securitygroup-private",
      "konvoy/securityGroup", "private"
    )
  )}"

  // Tags are added when LoadBalancer type services are created
  lifecycle {
    ignore_changes = ["ingress"]
  }
}

resource "aws_security_group" "konvoy_egress" {
  name        = "${local.sg_egress_name}"
  description = "Allow all egress communication."
  vpc_id      = "${local.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-securitygroup-egress",
      "konvoy/securityGroup", "egress"
    )
  )}"

  // Tags are added when LoadBalancer type services are created
  lifecycle {
    ignore_changes = ["ingress"]
  }
}

resource "aws_security_group" "konvoy_lb_control_plane" {
  name        = "${local.sg_control_plane_name}"
  description = "Allow inbound on 6443 for kube-apiserver load balancer."
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr_blocks}"]
  }

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-securitygroup-lb-control-plane",
      "konvoy/securityGroup", "lb-control-plane"
    )
  )}"
}
