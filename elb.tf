// There is a 32 char limit for ELB names, "-lb-control" is 11 chars + 1 dash between name and random_id so cluster_name must be truncated
// However, we don't want to just trim as that might trim the random_id,
// instead we should trim the provided var.cluster_name and then append random_id if required
// ELB name must only contain alphanumeric characters and hyphens, replace disallowed chars with "-"
locals {
  max_elb_name_length                    = 32
  suffix                                 = "-lb-control"
  max_length_when_random_id_used         = "${local.max_elb_name_length - length(local.suffix) - length(random_id.id.hex) - 1}"
  trimmed_cluster_name_with_random_id    = "${format("%s-%s", substr(var.cluster_name, 0, min(local.max_length_when_random_id_used, length(var.cluster_name))), random_id.id.hex)}"
  max_length_when_random_is_not_used     = "${local.max_elb_name_length - length(local.suffix)}"
  trimmed_cluster_name_without_random_id = "${substr(var.cluster_name, 0, min(local.max_length_when_random_is_not_used, length(var.cluster_name)))}"
  trimmed_cluster_name                   = "${var.cluster_name_random_string ? local.trimmed_cluster_name_with_random_id : local.trimmed_cluster_name_without_random_id}"
  replace_char                           = "-"
  replace_regex                          = "/[^a-zA-Z\\d-]/"
  elb_name                               = "${format("%s%s", replace(local.trimmed_cluster_name, local.replace_regex, local.replace_char), local.suffix)}"
  public_subnet_ids                      = "${split(",", length(var.public_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_public.*.id) : join(",", var.public_subnet_ids))}"
}

resource "aws_s3_bucket" "lb_logs" {
  count  = 0
  bucket = "${local.cluster_name}-lb-logs"
  acl    = "log-delivery-write"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-bucket-lb",
      "konvoy/bucket", "lb"
    )
  )}"
}

resource "aws_elb" "konvoy_control_plane" {
  name                      = "${local.elb_name}"
  internal                  = "${var.control_plane_elb_internal}"
  idle_timeout              = "${var.aws_control_plane_elb_idle_timeout}"
  security_groups           = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_lb_control_plane.id}"]
  subnets                   = ["${local.public_subnet_ids}"]
  connection_draining       = "True"
  cross_zone_load_balancing = "True"

  //access_logs {
  //  bucket = "${aws_s3_bucket.lb_logs.bucket}"
  //  bucket_prefix = "${local.cluster_name}/control_plane"
  //}
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:6443"
    interval            = 10
  }

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  instances = ["${aws_instance.control_plane.*.id}"]

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-lb-control-plane",
      "konvoy/loadBalancer", "control_plane"
    )
  )}"
}
