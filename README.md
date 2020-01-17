# CICD ISTIO installation on Kubernetes Cluster for Open Banking

ISTIO will be installed on Kubernetes cluster with sidecarInjectionWebhook initially disabled
--set sidecarInjectorWebhook.enabled=false 

The key reason for doing this is that there is a re-architecture of cloud environments under way i.e. all applications will be deployed in either Non_Prod or Prod cluster rather in their own K8S cluster. Individual projects will manually inject the sidecars in their services using either helm or istioctl kube-inject.


