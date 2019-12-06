locals {
  bastion_subnet_ids       = "${split(",", length(var.bastion_pool_subnet_ids) == 0 ? join(",", local.public_subnet_ids) : join(",", var.bastion_pool_subnet_ids))}"
  bastion_instance_profile = "${var.bastion_pool_iam_instance_profile_name != "" ? var.bastion_pool_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "bastion_pool_count" {
  description = "Number of bastion nodes"
  default     = 0
}

variable "bastion_pool_instance_type" {
  description = "[BASTION] Instance type"
  default     = "t3.small"
}

variable "bastion_pool_image_id" {
  description = "[BASTION] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "bastion_pool_root_volume_size" {
  description = "[BASTION] The root volume size"
  default     = "10"
}

variable "bastion_pool_root_volume_type" {
  description = "[BASTION] The root volume type. Should be gp2 or io1"
  default     = "gp2"
}

variable "bastion_pool_subnet_ids" {
  type        = "list"
  description = "[BASTION] Subnet to be used to deploy bastions on"
  default     = []
}

variable "bastion_pool_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "bastion" {
  vpc_security_group_ids      = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_ssh.id}", "${aws_security_group.konvoy_egress.id}"]
  subnet_id                   = "${element(local.bastion_subnet_ids, count.index % length(local.bastion_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.bastion_pool_count > 0 ? var.bastion_pool_count : 0}"
  ami                         = "${var.bastion_pool_image_id != "" ? var.bastion_pool_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.bastion_pool_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.bastion_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "true"

  root_block_device {
    volume_size           = "${var.bastion_pool_root_volume_size}"
    volume_type           = "${var.bastion_pool_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-bastion-${count.index}",
      "konvoy/nodeRoles", "bastion"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "bastion"
    )
  )}"
}
