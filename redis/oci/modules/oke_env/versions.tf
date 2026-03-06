terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    oci = {
      source = "oracle/oci"
      version = "8.4.0"
    }
  }
  required_version = ">= 0.14"
}
