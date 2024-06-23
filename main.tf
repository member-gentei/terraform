terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.6.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


resource "kubernetes_role" "github-runner" {
  metadata {
    name      = "github-runner"
    namespace = "gentei"
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["create", "get", "read", "update", "patch", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["create", "get", "read", "update", "patch", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "read", "update", "patch", "list"]
  }
  # read-only
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["Ingress"]
    verbs      = ["get", "read", "list"]
  }
}

resource "kubernetes_role_binding" "github-runner" {
  metadata {
    name      = "github-runner"
    namespace = "gentei"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "github-runner"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "actions-runner-system"
  }
}
