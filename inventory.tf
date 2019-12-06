// when bastion_pool_count > 0 the instances won't have public_dns
// don't add ansible_host: to the inventory
locals {
  inventory_format_with_ansible_host               = "    %s:\n      ansible_host: %s\n      node_pool: %s"
  inventory_format                                 = "    %s:\n%s      node_pool: %s"
  inventory_control_plane_format_with_ansible_host = "    %s:\n      ansible_host: %s"
  inventory_control_plane_format                   = "    %s:%s"
  bastion_vars_format                              = "    %s"
  bastion_hosts_format                             = "    %s:\n      ansible_host: %s"
}

// TODO
// Need to set order until https://github.com/ansible/ansible/issues/34861 is fixed to preserve order across runs
resource "local_file" "ansible_inventory" {
  filename = "${var.inventory_path}"

  provisioner "local-exec" {
    command = "chmod 644 ${var.inventory_path}"
  }

  content = <<EOF
all:
  vars:
    version: "${var.inventory_version}"
    order: sorted
    control_plane_endpoint: "${aws_elb.konvoy_control_plane.*.dns_name[0]}:6443"
    ansible_user: "${var.ssh_user}"
    ansible_port: 22
${chomp(join("\n", compact(list(
var.ssh_private_key_file == "" ? "" : "    ansible_ssh_private_key_file: \"${var.ssh_private_key_file}\"",
))))}

control-plane:
  hosts:
${join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_control_plane_format : local.inventory_control_plane_format_with_ansible_host, aws_instance.control_plane.*.private_ip, aws_instance.control_plane.*.public_dns))}

node:
${chomp(join("\n", list(
(var.worker_pool0_count > 0) || (var.worker_pool1_count > 0) || (var.worker_pool2_count > 0) || (var.worker_pool3_count > 0) || (var.worker_pool4_count > 0) || (var.worker_pool5_count > 0) || (var.worker_pool6_count > 0) || (var.worker_pool7_count > 0) || (var.worker_pool8_count > 0) || (var.worker_pool9_count > 0) || (false) ? "  hosts:" : "",
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool0.*.private_ip, aws_instance.worker_pool0.*.public_dns, var.worker_pool0_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool1.*.private_ip, aws_instance.worker_pool1.*.public_dns, var.worker_pool1_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool2.*.private_ip, aws_instance.worker_pool2.*.public_dns, var.worker_pool2_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool3.*.private_ip, aws_instance.worker_pool3.*.public_dns, var.worker_pool3_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool4.*.private_ip, aws_instance.worker_pool4.*.public_dns, var.worker_pool4_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool5.*.private_ip, aws_instance.worker_pool5.*.public_dns, var.worker_pool5_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool6.*.private_ip, aws_instance.worker_pool6.*.public_dns, var.worker_pool6_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool7.*.private_ip, aws_instance.worker_pool7.*.public_dns, var.worker_pool7_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool8.*.private_ip, aws_instance.worker_pool8.*.public_dns, var.worker_pool8_name)),
join("\n", formatlist((var.bastion_pool_count > 0) || (var.create_vpc_internet_gateway == "0") ? local.inventory_format : local.inventory_format_with_ansible_host, aws_instance.worker_pool9.*.private_ip, aws_instance.worker_pool9.*.public_dns, var.worker_pool9_name)),
)))}

bastion:
${var.bastion_pool_count == 0 ? "" : join("\n", concat(list("  hosts:"), formatlist(local.bastion_hosts_format, aws_instance.bastion.*.private_ip, aws_instance.bastion.*.public_dns)))}
${var.bastion_pool_count == 0 ? "" : join("\n", concat(list("  vars:"), formatlist(local.bastion_vars_format, compact(list("ansible_user: \"${var.ssh_user}\"", "ansible_port: 22"))))) }
EOF
}
