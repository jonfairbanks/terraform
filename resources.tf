## Digital Ocean
resource "digitalocean_kubernetes_cluster" "k8s" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = false
  version      = "1.18.8-do.1"

  node_pool {
    name       = "worker-pool"
    size       = "s-4vcpu-8gb"
    node_count = 2
  }
}

## Spaces
#resource "digitalocean_spaces_bucket" "static-assets" {
#  name   = var.do_space_name
#  region = "sfo2"
#}

## Metrics Server

resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "metrics-server"
  set {
    name  = "hostNetwork.enabled"
    value = "true"
  }
}

## Datadog 

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
  set_sensitive {
    name  = "datadog.apiKey"
    value = var.dd_api_key
  }
  set {
    name  = "datadog.processAgent.enabled"
    value = "true"
  }
  set {
    name  = "datadog.processAgent.processCollection"
    value = "true"
  }
  set {
    name  = "datadog.nodeLabelsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.podAnnotationsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.podLabelsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.apm.enabled"
    value = "true"
  }
  set {
    name  = "datadog.dogstatsd.nonLocalTraffic"
    value = "true"
  }
  set {
    name  = "datadog.dogstatsd.useHostPort"
    value = "true"
  }
  set {
    name  = "datadog.systemProbe.enabled"
    value = "true"
  }
}

## Nginx 

resource "helm_release" "ingress" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "nginx-ingress"
  name       = "ingress"
  set {
    name  = "controller.service.name"
    value = "nginx-ingress-controller"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
    value = "true"
  }
  set {
    name  = "controller.config.use-proxy-protocol"
    value = "true"
    type  = "string"
  }
  set {
    name  = "controller.config.proxy-body-size"
    value = "250m"
  }
  set {
    name  = "controller.config.client-max-body-size"
    value = "250m"
  }
  set {
    name  = "controller.config.proxy-connect-timeout"
    value = "60"
    type  = "string"
  }
  set {
    name  = "controller.config.proxy-read-timeout"
    value = "60"
    type  = "string"
  }
  set {
    name  = "defaultBackend.enabled"
    value = "false"
  }
  set {
    name  = "controller.defaultBackendService"
    value = "default/pretty-default-backend"
  }
}

resource "helm_release" "pretty-default-backend" {
  name       = "pretty-default-backend"
  repository = "https://h.cfcr.io/fairbanks.io/default"
  chart      = "pretty-default-backend"
  namespace  = "default"
  set {
    name  = "bgColor"
    value = "#334455"
  }
  set {
    name  = "brandingText"
    value = "bsord.dev/fairbanks.dev"
  }
}

## Argo CD

resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  set {
    name  = "installCRDs"
    value = "false"
  }
}
