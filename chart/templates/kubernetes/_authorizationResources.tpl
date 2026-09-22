
{{/*
  Defines templates for rendering Kubernetes workload resources, including:
  - ConfigMap
  - Secret
    - Image Registry (Docker) Secret
    - Service Account Token Secret
  - PersistentVolume
  - PersistentVolumeClaim

  In the following documentation:
  - HELPER KEYS - Gnoma template specific keys keys that can be used with that are NOT part of the Kubernetes
    resource, but rather conveniences to make defining Kubernetes resoruces less verbose or easier
  - DEFAULT KEYS - standard keys for the the Kubernetes resource, usually located at the top of the
    resource defintion or just under a standard catch-all key like "spec"
  - Gnoma SUPPORTING TEMPLATES - Gnoma templates that are shared among different Gnoma templates
    and called to render further data; e.g. every template calls "gnoma-common.apiObjectHeader", which
    in turn renders the metadata section found in every Kubernetes resource
*/}}

{{/*
  ======================================
  gnoma-kubernetes.clusterRole
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for ClusterRole

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      aggregationRule
      rules

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes ClusterRole.
*/}}
{{- define "gnoma-kubernetes.clusterRole" }}
  {{- $ := get . "$" }}
  {{- $roleValues := .gnomaTemplate }}

  {{- $_ := set $roleValues "kind" "ClusterRole" }}
  {{- include "gnoma-kubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.clusterRoleBinding
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for ClusterRoleBinding

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      roleRef
      subjects

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes ClusterRoleBinding.
*/}}
{{- define "gnoma-kubernetes.clusterRoleBinding" }}
  {{- $ := get . "$" }}
  {{- $clusterRoleBindingValues := .gnomaTemplate }}

  {{- $_ := set $clusterRoleBindingValues "kind" "ClusterRoleBinding" }}
  {{- include "gnoma-kubernetes.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.role
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for Role

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      aggregationRule
      rules

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes Role.
*/}}
{{- define "gnoma-kubernetes.role" }}
  {{- $ := get . "$" }}
  {{- $roleValues := .gnomaTemplate }}

  {{- $_ := set $roleValues "kind" "Role" }}
  {{- include "gnoma-kubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.roleBinding
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for RoleBinding

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      roleRef
      subjects

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes RoleBinding.
*/}}
{{- define "gnoma-kubernetes.roleBinding" }}
  {{- $ := get . "$" }}
  {{- $roleBindingValues := .gnomaTemplate }}

  {{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
  {{- include "gnoma-kubernetes.genericRoleBindingDefinition" . }}
{{- end }}
