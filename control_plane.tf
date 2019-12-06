locals {
  control_plane_subnet_ids                  = "${split(",", length(var.control_plane_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_control_plane.*.id) : join(",", var.control_plane_subnet_ids))}"
  control_plane_security_group              = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_ssh.id}", "${aws_security_group.konvoy_egress.id}"]
  control_plane_security_group_with_bastion = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_egress.id}"]
  control_plane_instance_profile            = "${var.control_plane_iam_instance_profile_name != "" ? var.control_plane_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "control_plane_count" {
  description = "Number of k8s control plane nodes"
}

variable "control_plane_instance_type" {
  description = "[CONTROL_PLANE] Instance type"
  default     = "t3.large"
}

variable "control_plane_image_id" {
  description = "[CONTROL_PLANE] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "control_plane_root_volume_size" {
  description = "[CONTROL_PLANE] The root volume size"
  default     = "80"
}

variable "control_plane_root_volume_type" {
  description = "[CONTROL_PLANE] The root volume type. Should be gp2 or io1"
  default     = "gp2"
}

variable "control_plane_imagefs_volume_enabled" {
  description = "[CONTROL_PLANE] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "control_plane_imagefs_volume_size" {
  description = "[CONTROL_PLANE] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "control_plane_imagefs_volume_type" {
  description = "[CONTROL_PLANE] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "control_plane_imagefs_volume_device" {
  description = "[CONTROL_PLANE] The device to mount the volume at."
  default     = "xvdb"
}

variable "control_plane_elb_internal" {
  description = "[CONTROL_PLANE] If the control plane ELB should be internal"
  default     = false
}

variable "aws_control_plane_elb_idle_timeout" {
  description = "[CONTROL_PLANE] Amount of time an ELB connection can remain idle before being closed"

  // 3600s = 1h, so that we can stream output from logs or port-forwarding longer
  default = "3600"
}

variable "control_plane_associate_public_ip_address" {
  description = "[CONTROL_PLANE] Used to disable public IP association"
  default     = true
}

variable "control_plane_subnet_ids" {
  type        = "list"
  description = "[CONTROL_PLANE] Subnet to be used for the control plane"
  default     = []
}

variable "control_plane_iam_instance_profile_name" {
  description = "[CONTROL_PLANE] Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "control_plane" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.control_plane_security_group_with_bastion) : join(",", local.control_plane_security_group))}"]
  subnet_id                   = "${element(local.control_plane_subnet_ids, count.index % length(local.control_plane_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.control_plane_count}"
  ami                         = "${var.control_plane_image_id != "" ? var.control_plane_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.control_plane_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.control_plane_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.control_plane_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.control_plane_root_volume_size}"
    volume_type           = "${var.control_plane_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-control-plane-${count.index}",
      "konvoy/nodeRoles", "control_plane"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "control_plane"
    )
  )}"

  // Ignore volume_tags because of https://github.com/terraform-providers/terraform-provider-aws/issues/729
  // TF removes labels on additional EBS volumes attached to the instance, including those created by the CSI driver
  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "control_plane_imagefs" {
  count             = "${var.control_plane_imagefs_volume_enabled ? var.control_plane_count : 0}"
  availability_zone = "${element(aws_instance.control_plane.*.availability_zone, count.index)}"
  type              = "${var.control_plane_imagefs_volume_type}"
  size              = "${var.control_plane_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-control-plane-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "control_plane"
    )
  )}"
}

resource "aws_volume_attachment" "control_plane_imagefs" {
  count        = "${var.control_plane_imagefs_volume_enabled ? var.control_plane_count : 0}"
  device_name  = "/dev/${var.control_plane_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.control_plane_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.control_plane.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}
