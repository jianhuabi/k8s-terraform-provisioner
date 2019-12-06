# k8s-terraform-provisioner

A simple `terraform module` to provision a empty k8s cluster, default setup create a cluster with 3 master and 4 worker.

You can then use `D2iQ konvoy` or `kubeadm` to install `kubernete` in this cluster. 

## 0. Prereq

You need to prep a `ssh x509 certs` pair under this project folder. Example like:

```
ssh-keygen -P "" -f key_name
```

## 1. module init

```
terraform init
```

## 2. generate dry-run plan

```
terraform plan -out=plan.out -var-file=./variables.konvoy.tfvars
```

## 3. execute plan
```
terraform apply plan.out
```

## 4. destroy plan

```
terraform destroy -var-file=./variables.konvoy.tfvars.json
```

## 5. configuration

```json
{
    "inventory_version": "v1.2.5",
    "provider"         : "aws",
    "cluster_name"     : "dangdang-konvoy-v1.2.5",
    "konvoy_version"   : "v1.2.5",

    "inventory_path": "/Users/michaelbi/mesosphere/konvoy/konvoy_terraform/v1.2.5/aws/inventory.yaml",

    "ssh_user": "centos",
    "ssh_public_key_file": "./konvoy_v1.2.5-ssh.pub", 
    "ssh_private_key_file": "konvoy_v1.2.5-ssh.pem",

    "aws_region": "us-west-2",
    "aws_availability_zones": [
        "us-west-2c"
    ],
    "aws_tags": {
        "owner": "michaelbi"
    },

    "create_vpc_internet_gateway": true,
    "create_iam_instance_profile": true,

    "control_plane_count" : 3,
    "control_plane_instance_type": "t3.xlarge",
    "control_plane_root_volume_type": "gp2",
    "control_plane_root_volume_size": 80,
    "control_plane_imagefs_volume_enabled": true,
    "control_plane_imagefs_volume_type": "gp2",
    "control_plane_imagefs_volume_size": 160,

    "worker_pool0_count": 4,
    "worker_pool0_name": "worker",
    "worker_pool0_instance_type": "t3.2xlarge",
    "worker_pool0_root_volume_type": "gp2",
    "worker_pool0_root_volume_size": 80,
    "worker_pool0_imagefs_volume_enabled": true,
    "worker_pool0_imagefs_volume_type": "gp2",
    "worker_pool0_imagefs_volume_size": 160,
    "worker_pool0_associate_public_ip_address": true
}
```

## 6. inventory.yaml to bootstrap konvoy will be auto created for you

