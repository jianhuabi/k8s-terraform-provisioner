provider "aws" {
  version = "~> 2.4"
  region  = "${var.aws_region}"
}

provider "local" {
  version = "~> 1.2"
}

provider "random" {
  version = "~> 2.1"
}

// if availability zones is not set request the available in this region
data "aws_availability_zones" "available" {}

resource "random_id" "id" {
  byte_length = 2
}

resource "aws_key_pair" "konvoy" {
  key_name   = "${local.cluster_name}"
  public_key = "${file("${var.ssh_public_key_file}")}"
}

locals {
  common_tags = "${merge(
    var.aws_tags,
    map("konvoy/clusterName", "${local.cluster_name}",
      "konvoy/version", "${var.konvoy_version}",
      "kubernetes.io/cluster", "${local.cluster_name}",
      "kubernetes.io/cluster/${local.cluster_name}", "owned"
    )
  )}"

  common_tags_no_cluster = "${merge(
    var.aws_tags,
    map("konvoy/clusterName", "${local.cluster_name}",
      "konvoy/version", "${var.konvoy_version}",
    )
  )}"

  cluster_name = "${var.cluster_name_random_string ? format("%s-%s", var.cluster_name, random_id.id.hex) : var.cluster_name}"
}

//=====================================================================
//= Output variables
//=====================================================================

output "vpc_id" {
  value = "${var.vpc_id == "" ? join(",", aws_vpc.konvoy.*.id) : var.vpc_id}"
}

output "cluster_name" {
  value = "${local.cluster_name}"
}
