locals {
  worker_security_group              = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_ssh.id}", "${aws_security_group.konvoy_egress.id}"]
  worker_security_group_with_bastion = ["${aws_security_group.konvoy_private.id}", "${aws_security_group.konvoy_egress.id}"]
}

locals {
  worker0_subnet_ids       = "${split(",", length(var.worker_pool0_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool0_subnet_ids))}"
  worker0_instance_profile = "${var.worker_pool0_iam_instance_profile_name != "" ? var.worker_pool0_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool0_name" {
  description = "The name for worker pool 0"
  default     = "worker0"
}

variable "worker_pool0_count" {
  description = "Number of k8s nodes for worker pool 0"
  default     = 0
}

variable "worker_pool0_instance_type" {
  description = "[WORKER POOL 0] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool0_image_id" {
  description = "[WORKER POOL 0] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool0_root_volume_size" {
  description = "[WORKER POOL 0] The root volume size"
  default     = "80"
}

variable "worker_pool0_root_volume_type" {
  description = "[WORKER POOL 0] The root volume type"
  default     = ""
}

variable "worker_pool0_imagefs_volume_enabled" {
  description = "[WORKER POOL 0] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool0_imagefs_volume_size" {
  description = "[WORKER POOL 0] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool0_imagefs_volume_type" {
  description = "[WORKER POOL 0] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool0_imagefs_volume_device" {
  description = "[WORKER POOL 0] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool0_associate_public_ip_address" {
  description = "[WORKER POOL 0] Used to disable public IP association"
  default     = true
}

variable "worker_pool0_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 0] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool0_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool0" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker0_subnet_ids, count.index % length(local.worker0_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool0_count}"
  ami                         = "${var.worker_pool0_image_id != "" ? var.worker_pool0_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool0_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker0_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool0_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool0_root_volume_size}"
    volume_type           = "${var.worker_pool0_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool0_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool0_imagefs" {
  count             = "${var.worker_pool0_imagefs_volume_enabled ? var.worker_pool0_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool0.*.availability_zone, count.index)}"
  type              = "${var.worker_pool0_imagefs_volume_type}"
  size              = "${var.worker_pool0_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-0-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool0_imagefs" {
  count        = "${var.worker_pool0_imagefs_volume_enabled ? var.worker_pool0_count : 0}"
  device_name  = "/dev/${var.worker_pool0_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool0_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool0.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker1_subnet_ids       = "${split(",", length(var.worker_pool1_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool1_subnet_ids))}"
  worker1_instance_profile = "${var.worker_pool1_iam_instance_profile_name != "" ? var.worker_pool1_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool1_name" {
  description = "The name for worker pool 1"
  default     = "worker1"
}

variable "worker_pool1_count" {
  description = "Number of k8s nodes for worker pool 1"
  default     = 0
}

variable "worker_pool1_instance_type" {
  description = "[WORKER POOL 1] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool1_image_id" {
  description = "[WORKER POOL 1] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool1_root_volume_size" {
  description = "[WORKER POOL 1] The root volume size"
  default     = "80"
}

variable "worker_pool1_root_volume_type" {
  description = "[WORKER POOL 1] The root volume type"
  default     = ""
}

variable "worker_pool1_imagefs_volume_enabled" {
  description = "[WORKER POOL 1] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool1_imagefs_volume_size" {
  description = "[WORKER POOL 1] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool1_imagefs_volume_type" {
  description = "[WORKER POOL 1] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool1_imagefs_volume_device" {
  description = "[WORKER POOL 1] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool1_associate_public_ip_address" {
  description = "[WORKER POOL 1] Used to disable public IP association"
  default     = true
}

variable "worker_pool1_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 1] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool1_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool1" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker1_subnet_ids, count.index % length(local.worker1_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool1_count}"
  ami                         = "${var.worker_pool1_image_id != "" ? var.worker_pool1_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool1_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker1_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool1_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool1_root_volume_size}"
    volume_type           = "${var.worker_pool1_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool1_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool1_imagefs" {
  count             = "${var.worker_pool1_imagefs_volume_enabled ? var.worker_pool1_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool1.*.availability_zone, count.index)}"
  type              = "${var.worker_pool1_imagefs_volume_type}"
  size              = "${var.worker_pool1_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-1-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool1_imagefs" {
  count        = "${var.worker_pool1_imagefs_volume_enabled ? var.worker_pool1_count : 0}"
  device_name  = "/dev/${var.worker_pool1_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool1_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool1.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker2_subnet_ids       = "${split(",", length(var.worker_pool2_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool2_subnet_ids))}"
  worker2_instance_profile = "${var.worker_pool2_iam_instance_profile_name != "" ? var.worker_pool2_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool2_name" {
  description = "The name for worker pool 2"
  default     = "worker2"
}

variable "worker_pool2_count" {
  description = "Number of k8s nodes for worker pool 2"
  default     = 0
}

variable "worker_pool2_instance_type" {
  description = "[WORKER POOL 2] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool2_image_id" {
  description = "[WORKER POOL 2] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool2_root_volume_size" {
  description = "[WORKER POOL 2] The root volume size"
  default     = "80"
}

variable "worker_pool2_root_volume_type" {
  description = "[WORKER POOL 2] The root volume type"
  default     = ""
}

variable "worker_pool2_imagefs_volume_enabled" {
  description = "[WORKER POOL 2] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool2_imagefs_volume_size" {
  description = "[WORKER POOL 2] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool2_imagefs_volume_type" {
  description = "[WORKER POOL 2] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool2_imagefs_volume_device" {
  description = "[WORKER POOL 2] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool2_associate_public_ip_address" {
  description = "[WORKER POOL 2] Used to disable public IP association"
  default     = true
}

variable "worker_pool2_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 2] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool2_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool2" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker2_subnet_ids, count.index % length(local.worker2_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool2_count}"
  ami                         = "${var.worker_pool2_image_id != "" ? var.worker_pool2_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool2_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker2_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool2_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool2_root_volume_size}"
    volume_type           = "${var.worker_pool2_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool2_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool2_imagefs" {
  count             = "${var.worker_pool2_imagefs_volume_enabled ? var.worker_pool2_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool2.*.availability_zone, count.index)}"
  type              = "${var.worker_pool2_imagefs_volume_type}"
  size              = "${var.worker_pool2_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-2-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool2_imagefs" {
  count        = "${var.worker_pool2_imagefs_volume_enabled ? var.worker_pool2_count : 0}"
  device_name  = "/dev/${var.worker_pool2_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool2_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool2.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker3_subnet_ids       = "${split(",", length(var.worker_pool3_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool3_subnet_ids))}"
  worker3_instance_profile = "${var.worker_pool3_iam_instance_profile_name != "" ? var.worker_pool3_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool3_name" {
  description = "The name for worker pool 3"
  default     = "worker3"
}

variable "worker_pool3_count" {
  description = "Number of k8s nodes for worker pool 3"
  default     = 0
}

variable "worker_pool3_instance_type" {
  description = "[WORKER POOL 3] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool3_image_id" {
  description = "[WORKER POOL 3] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool3_root_volume_size" {
  description = "[WORKER POOL 3] The root volume size"
  default     = "80"
}

variable "worker_pool3_root_volume_type" {
  description = "[WORKER POOL 3] The root volume type"
  default     = ""
}

variable "worker_pool3_imagefs_volume_enabled" {
  description = "[WORKER POOL 3] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool3_imagefs_volume_size" {
  description = "[WORKER POOL 3] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool3_imagefs_volume_type" {
  description = "[WORKER POOL 3] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool3_imagefs_volume_device" {
  description = "[WORKER POOL 3] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool3_associate_public_ip_address" {
  description = "[WORKER POOL 3] Used to disable public IP association"
  default     = true
}

variable "worker_pool3_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 3] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool3_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool3" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker3_subnet_ids, count.index % length(local.worker3_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool3_count}"
  ami                         = "${var.worker_pool3_image_id != "" ? var.worker_pool3_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool3_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker3_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool3_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool3_root_volume_size}"
    volume_type           = "${var.worker_pool3_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool3_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool3_imagefs" {
  count             = "${var.worker_pool3_imagefs_volume_enabled ? var.worker_pool3_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool3.*.availability_zone, count.index)}"
  type              = "${var.worker_pool3_imagefs_volume_type}"
  size              = "${var.worker_pool3_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-3-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool3_imagefs" {
  count        = "${var.worker_pool3_imagefs_volume_enabled ? var.worker_pool3_count : 0}"
  device_name  = "/dev/${var.worker_pool3_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool3_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool3.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker4_subnet_ids       = "${split(",", length(var.worker_pool4_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool4_subnet_ids))}"
  worker4_instance_profile = "${var.worker_pool4_iam_instance_profile_name != "" ? var.worker_pool4_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool4_name" {
  description = "The name for worker pool 4"
  default     = "worker4"
}

variable "worker_pool4_count" {
  description = "Number of k8s nodes for worker pool 4"
  default     = 0
}

variable "worker_pool4_instance_type" {
  description = "[WORKER POOL 4] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool4_image_id" {
  description = "[WORKER POOL 4] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool4_root_volume_size" {
  description = "[WORKER POOL 4] The root volume size"
  default     = "80"
}

variable "worker_pool4_root_volume_type" {
  description = "[WORKER POOL 4] The root volume type"
  default     = ""
}

variable "worker_pool4_imagefs_volume_enabled" {
  description = "[WORKER POOL 4] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool4_imagefs_volume_size" {
  description = "[WORKER POOL 4] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool4_imagefs_volume_type" {
  description = "[WORKER POOL 4] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool4_imagefs_volume_device" {
  description = "[WORKER POOL 4] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool4_associate_public_ip_address" {
  description = "[WORKER POOL 4] Used to disable public IP association"
  default     = true
}

variable "worker_pool4_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 4] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool4_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool4" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker4_subnet_ids, count.index % length(local.worker4_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool4_count}"
  ami                         = "${var.worker_pool4_image_id != "" ? var.worker_pool4_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool4_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker4_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool4_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool4_root_volume_size}"
    volume_type           = "${var.worker_pool4_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool4_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool4_imagefs" {
  count             = "${var.worker_pool4_imagefs_volume_enabled ? var.worker_pool4_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool4.*.availability_zone, count.index)}"
  type              = "${var.worker_pool4_imagefs_volume_type}"
  size              = "${var.worker_pool4_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-4-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool4_imagefs" {
  count        = "${var.worker_pool4_imagefs_volume_enabled ? var.worker_pool4_count : 0}"
  device_name  = "/dev/${var.worker_pool4_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool4_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool4.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker5_subnet_ids       = "${split(",", length(var.worker_pool5_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool5_subnet_ids))}"
  worker5_instance_profile = "${var.worker_pool5_iam_instance_profile_name != "" ? var.worker_pool5_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool5_name" {
  description = "The name for worker pool 5"
  default     = "worker5"
}

variable "worker_pool5_count" {
  description = "Number of k8s nodes for worker pool 5"
  default     = 0
}

variable "worker_pool5_instance_type" {
  description = "[WORKER POOL 5] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool5_image_id" {
  description = "[WORKER POOL 5] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool5_root_volume_size" {
  description = "[WORKER POOL 5] The root volume size"
  default     = "80"
}

variable "worker_pool5_root_volume_type" {
  description = "[WORKER POOL 5] The root volume type"
  default     = ""
}

variable "worker_pool5_imagefs_volume_enabled" {
  description = "[WORKER POOL 5] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool5_imagefs_volume_size" {
  description = "[WORKER POOL 5] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool5_imagefs_volume_type" {
  description = "[WORKER POOL 5] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool5_imagefs_volume_device" {
  description = "[WORKER POOL 5] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool5_associate_public_ip_address" {
  description = "[WORKER POOL 5] Used to disable public IP association"
  default     = true
}

variable "worker_pool5_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 5] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool5_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool5" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker5_subnet_ids, count.index % length(local.worker5_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool5_count}"
  ami                         = "${var.worker_pool5_image_id != "" ? var.worker_pool5_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool5_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker5_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool5_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool5_root_volume_size}"
    volume_type           = "${var.worker_pool5_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool5_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool5_imagefs" {
  count             = "${var.worker_pool5_imagefs_volume_enabled ? var.worker_pool5_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool5.*.availability_zone, count.index)}"
  type              = "${var.worker_pool5_imagefs_volume_type}"
  size              = "${var.worker_pool5_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-5-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool5_imagefs" {
  count        = "${var.worker_pool5_imagefs_volume_enabled ? var.worker_pool5_count : 0}"
  device_name  = "/dev/${var.worker_pool5_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool5_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool5.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker6_subnet_ids       = "${split(",", length(var.worker_pool6_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool6_subnet_ids))}"
  worker6_instance_profile = "${var.worker_pool6_iam_instance_profile_name != "" ? var.worker_pool6_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool6_name" {
  description = "The name for worker pool 6"
  default     = "worker6"
}

variable "worker_pool6_count" {
  description = "Number of k8s nodes for worker pool 6"
  default     = 0
}

variable "worker_pool6_instance_type" {
  description = "[WORKER POOL 6] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool6_image_id" {
  description = "[WORKER POOL 6] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool6_root_volume_size" {
  description = "[WORKER POOL 6] The root volume size"
  default     = "80"
}

variable "worker_pool6_root_volume_type" {
  description = "[WORKER POOL 6] The root volume type"
  default     = ""
}

variable "worker_pool6_imagefs_volume_enabled" {
  description = "[WORKER POOL 6] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool6_imagefs_volume_size" {
  description = "[WORKER POOL 6] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool6_imagefs_volume_type" {
  description = "[WORKER POOL 6] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool6_imagefs_volume_device" {
  description = "[WORKER POOL 6] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool6_associate_public_ip_address" {
  description = "[WORKER POOL 6] Used to disable public IP association"
  default     = true
}

variable "worker_pool6_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 6] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool6_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool6" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker6_subnet_ids, count.index % length(local.worker6_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool6_count}"
  ami                         = "${var.worker_pool6_image_id != "" ? var.worker_pool6_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool6_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker6_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool6_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool6_root_volume_size}"
    volume_type           = "${var.worker_pool6_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool6_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool6_imagefs" {
  count             = "${var.worker_pool6_imagefs_volume_enabled ? var.worker_pool6_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool6.*.availability_zone, count.index)}"
  type              = "${var.worker_pool6_imagefs_volume_type}"
  size              = "${var.worker_pool6_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-6-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool6_imagefs" {
  count        = "${var.worker_pool6_imagefs_volume_enabled ? var.worker_pool6_count : 0}"
  device_name  = "/dev/${var.worker_pool6_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool6_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool6.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker7_subnet_ids       = "${split(",", length(var.worker_pool7_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool7_subnet_ids))}"
  worker7_instance_profile = "${var.worker_pool7_iam_instance_profile_name != "" ? var.worker_pool7_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool7_name" {
  description = "The name for worker pool 7"
  default     = "worker7"
}

variable "worker_pool7_count" {
  description = "Number of k8s nodes for worker pool 7"
  default     = 0
}

variable "worker_pool7_instance_type" {
  description = "[WORKER POOL 7] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool7_image_id" {
  description = "[WORKER POOL 7] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool7_root_volume_size" {
  description = "[WORKER POOL 7] The root volume size"
  default     = "80"
}

variable "worker_pool7_root_volume_type" {
  description = "[WORKER POOL 7] The root volume type"
  default     = ""
}

variable "worker_pool7_imagefs_volume_enabled" {
  description = "[WORKER POOL 7] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool7_imagefs_volume_size" {
  description = "[WORKER POOL 7] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool7_imagefs_volume_type" {
  description = "[WORKER POOL 7] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool7_imagefs_volume_device" {
  description = "[WORKER POOL 7] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool7_associate_public_ip_address" {
  description = "[WORKER POOL 7] Used to disable public IP association"
  default     = true
}

variable "worker_pool7_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 7] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool7_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool7" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker7_subnet_ids, count.index % length(local.worker7_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool7_count}"
  ami                         = "${var.worker_pool7_image_id != "" ? var.worker_pool7_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool7_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker7_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool7_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool7_root_volume_size}"
    volume_type           = "${var.worker_pool7_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool7_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool7_imagefs" {
  count             = "${var.worker_pool7_imagefs_volume_enabled ? var.worker_pool7_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool7.*.availability_zone, count.index)}"
  type              = "${var.worker_pool7_imagefs_volume_type}"
  size              = "${var.worker_pool7_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-7-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool7_imagefs" {
  count        = "${var.worker_pool7_imagefs_volume_enabled ? var.worker_pool7_count : 0}"
  device_name  = "/dev/${var.worker_pool7_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool7_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool7.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker8_subnet_ids       = "${split(",", length(var.worker_pool8_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool8_subnet_ids))}"
  worker8_instance_profile = "${var.worker_pool8_iam_instance_profile_name != "" ? var.worker_pool8_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool8_name" {
  description = "The name for worker pool 8"
  default     = "worker8"
}

variable "worker_pool8_count" {
  description = "Number of k8s nodes for worker pool 8"
  default     = 0
}

variable "worker_pool8_instance_type" {
  description = "[WORKER POOL 8] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool8_image_id" {
  description = "[WORKER POOL 8] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool8_root_volume_size" {
  description = "[WORKER POOL 8] The root volume size"
  default     = "80"
}

variable "worker_pool8_root_volume_type" {
  description = "[WORKER POOL 8] The root volume type"
  default     = ""
}

variable "worker_pool8_imagefs_volume_enabled" {
  description = "[WORKER POOL 8] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool8_imagefs_volume_size" {
  description = "[WORKER POOL 8] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool8_imagefs_volume_type" {
  description = "[WORKER POOL 8] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool8_imagefs_volume_device" {
  description = "[WORKER POOL 8] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool8_associate_public_ip_address" {
  description = "[WORKER POOL 8] Used to disable public IP association"
  default     = true
}

variable "worker_pool8_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 8] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool8_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool8" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker8_subnet_ids, count.index % length(local.worker8_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool8_count}"
  ami                         = "${var.worker_pool8_image_id != "" ? var.worker_pool8_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool8_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker8_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool8_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool8_root_volume_size}"
    volume_type           = "${var.worker_pool8_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool8_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool8_imagefs" {
  count             = "${var.worker_pool8_imagefs_volume_enabled ? var.worker_pool8_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool8.*.availability_zone, count.index)}"
  type              = "${var.worker_pool8_imagefs_volume_type}"
  size              = "${var.worker_pool8_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-8-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool8_imagefs" {
  count        = "${var.worker_pool8_imagefs_volume_enabled ? var.worker_pool8_count : 0}"
  device_name  = "/dev/${var.worker_pool8_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool8_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool8.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}

locals {
  worker9_subnet_ids       = "${split(",", length(var.worker_pool9_subnet_ids) == 0 ? join(",", aws_subnet.konvoy_private.*.id) : join(",", var.worker_pool9_subnet_ids))}"
  worker9_instance_profile = "${var.worker_pool9_iam_instance_profile_name != "" ? var.worker_pool9_iam_instance_profile_name : join("", aws_iam_instance_profile.node_profile.*.id)}"
}

variable "worker_pool9_name" {
  description = "The name for worker pool 9"
  default     = "worker9"
}

variable "worker_pool9_count" {
  description = "Number of k8s nodes for worker pool 9"
  default     = 0
}

variable "worker_pool9_instance_type" {
  description = "[WORKER POOL 9] Instance type"
  default     = "t3.xlarge"
}

variable "worker_pool9_image_id" {
  description = "[WORKER POOL 9] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "worker_pool9_root_volume_size" {
  description = "[WORKER POOL 9] The root volume size"
  default     = "80"
}

variable "worker_pool9_root_volume_type" {
  description = "[WORKER POOL 9] The root volume type"
  default     = ""
}

variable "worker_pool9_imagefs_volume_enabled" {
  description = "[WORKER POOL 9] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_pool9_imagefs_volume_size" {
  description = "[WORKER POOL 9] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_pool9_imagefs_volume_type" {
  description = "[WORKER POOL 9] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_pool9_imagefs_volume_device" {
  description = "[WORKER POOL 9] The device to mount the volume at."
  default     = "xvdb"
}

variable "worker_pool9_associate_public_ip_address" {
  description = "[WORKER POOL 9] Used to disable public IP association"
  default     = true
}

variable "worker_pool9_subnet_ids" {
  type        = "list"
  description = "[WORKER POOL 9] Subnets to be used to deploy workers"
  default     = []
}

variable "worker_pool9_iam_instance_profile_name" {
  description = "Pre-existing iam instanceProfile name to use"
  default     = ""
}

resource "aws_instance" "worker_pool9" {
  vpc_security_group_ids      = ["${split(",", var.bastion_pool_count > 0 ? join(",", local.worker_security_group_with_bastion) : join(",", local.worker_security_group))}"]
  subnet_id                   = "${element(local.worker9_subnet_ids, count.index % length(local.worker9_subnet_ids))}"
  key_name                    = "${local.cluster_name}"
  count                       = "${var.worker_pool9_count}"
  ami                         = "${var.worker_pool9_image_id != "" ? var.worker_pool9_image_id : lookup(local.default_ami_ids, format("centos7_%s", coalesce(var.aws_region, data.aws_region.current.name)))}"
  instance_type               = "${var.worker_pool9_instance_type}"
  availability_zone           = "${element(coalescelist(var.aws_availability_zones, data.aws_availability_zones.available.names), count.index)}"
  iam_instance_profile        = "${local.worker9_instance_profile}"
  source_dest_check           = "false"
  associate_public_ip_address = "${var.bastion_pool_count > 0 ? false : var.worker_pool9_associate_public_ip_address}"

  root_block_device {
    volume_size           = "${var.worker_pool9_root_volume_size}"
    volume_type           = "${var.worker_pool9_root_volume_type}"
    delete_on_termination = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.cluster_name}-${var.worker_pool9_name}-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"

  volume_tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "konvoy/nodeRoles", "worker"
    )
  )}"

  lifecycle {
    ignore_changes = ["tags.%", "volume_tags.%", "volume_tags.CSIVolumeName", "volume_tags.Name"]
  }
}

resource "aws_ebs_volume" "worker_pool9_imagefs" {
  count             = "${var.worker_pool9_imagefs_volume_enabled ? var.worker_pool9_count : 0}"
  availability_zone = "${element(aws_instance.worker_pool9.*.availability_zone, count.index)}"
  type              = "${var.worker_pool9_imagefs_volume_type}"
  size              = "${var.worker_pool9_imagefs_volume_size}"

  tags = "${merge(
    local.common_tags_no_cluster,
    map(
      "Name", "${local.cluster_name}-worker-pool-9-volume-imagefs-${count.index}",
      "konvoy/nodeRoles", "worker"
    )
  )}"
}

resource "aws_volume_attachment" "worker_pool9_imagefs" {
  count        = "${var.worker_pool9_imagefs_volume_enabled ? var.worker_pool9_count : 0}"
  device_name  = "/dev/${var.worker_pool9_imagefs_volume_device}"
  volume_id    = "${element(aws_ebs_volume.worker_pool9_imagefs.*.id, count.index)}"
  instance_id  = "${element(aws_instance.worker_pool9.*.id, count.index)}"
  force_detach = true

  lifecycle {
    ignore_changes = ["volume", "instance"]
  }
}
