variable "do_token" {}
variable "do_cluster_name" {}
variable "dd_api_key" {}

###
# Terraform Cloud
###

terraform {
  backend "remote" {
    organization = "Fairbanks-io"

    workspaces {
      name = "k8s-prod-us-sfo"
    }
  }
}

###
# DigitalOcean
###

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = true
  version      = "1.18.6-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.k8s.id
}

###
# Helm
###

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = digitalocean_kubernetes_cluster.k8s.endpoint
    token                  = digitalocean_kubernetes_cluster.k8s.kube_config.0.token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "keel" {
  name       = "keel"
  repository = "https://charts.keel.sh"
  chart      = "keel"
  namespace  = "kube-system"
  set {
    name  = "helmProvider.version"
    value = "v3"
  }
}

resource "helm_release" "ingress" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "nginx-ingress"
  name       = "ingress"
  set {
    name  = "controller.service.name"
    value = "nginx-ingress-controller"
  }
}

resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

resource "helm_release" "datadog" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "datadog"
  name       = "datadog"
  namespace  = "datadog"
  set {
    name  = "datadog.apiKey"
    value = var.dd_api_key
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = digitalocean_kubernetes_cluster.k8s.endpoint
  token                  = digitalocean_kubernetes_cluster.k8s.kube_config.0.token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

data "kubernetes_service" "nginx-ingress-controller" {
  metadata {
    name = "ingress-nginx-ingress-controller"
  }
  depends_on = [helm_release.ingress]
}

##
# Output
##

output "ingress-ip" {
  value = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
}