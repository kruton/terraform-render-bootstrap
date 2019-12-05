# Assets generated only when certain options are chosen

locals {
  # flannel manifests (manifest.yaml => content)
  flannel_manifests = {
    for name in fileset("${path.module}/resources/flannel", "*.yaml"):
    "manifests-networking/${name}" => templatefile(
      "${path.module}/resources/flannel/${name}",
      {
        flannel_image     = var.container_images["flannel"]
        flannel_cni_image = var.container_images["flannel_cni"]
        pod_cidr          = var.pod_cidr
      }
    )
    if var.networking == "flannel"
  }

  # calico manifests (manifest.yaml => content)
  calico_manifests = {
    for name in fileset("${path.module}/resources/calico", "*.yaml"):
    "manifests-networking/${name}" => templatefile(
      "${path.module}/resources/calico/${name}",
      {
        calico_image                    = var.container_images["calico"]
        calico_cni_image                = var.container_images["calico_cni"]
        network_mtu                     = var.network_mtu
        network_encapsulation           = indent(2, var.network_encapsulation == "vxlan" ? "vxlanMode: Always" : "ipipMode: Always")
        ipip_enabled                    = var.network_encapsulation == "ipip" ? true : false
        ipip_readiness                  = var.network_encapsulation == "ipip" ? indent(16, "- --bird-ready") : ""
        vxlan_enabled                   = var.network_encapsulation == "vxlan" ? true : false
        network_ip_autodetection_method = var.network_ip_autodetection_method
        pod_cidr                        = var.pod_cidr
        pod_cidr_ipv6                   = var.pod_cidr_ipv6
        enable_reporting                = var.enable_reporting
      }
    )
    if var.networking == "calico"
  }

  # kube-router manifests (manifest.yaml => content)
  kube_router_manifests = {
    for name in fileset("${path.module}/resources/kube-router", "*.yaml"):
    "manifests-networking/${name}" => templatefile(
      "${path.module}/resources/kube-router/${name}",
      {
        kube_router_image = var.container_images["kube_router"]
        flannel_cni_image = var.container_images["flannel_cni"]
        network_mtu       = var.network_mtu
      }
    )
    if var.networking == "kube-router"
  }
}

# flannel manifests
resource "local_file" "flannel-manifests" {
  for_each = local.flannel_manifests

  filename = "${var.asset_dir}/${each.key}"
  content  = each.value
}

# Calico manifests
resource "local_file" "calico-manifests" {
  for_each = local.calico_manifests

  filename = "${var.asset_dir}/${each.key}"
  content  = each.value
}

# kube-router manifests
resource "local_file" "kube-router-manifests" {
  for_each = local.kube_router_manifests

  filename = "${var.asset_dir}/${each.key}"
  content  = each.value
}
