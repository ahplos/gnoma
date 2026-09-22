{{/*
  Defines templates for rendering Kubernetes workload resources, including:
  - Namespace
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
  gnoma-kubernetes.namespace
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $nsValues -> Gnoma template for Namespace

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes Namespace.
*/}}
{{- define "gnoma-kubernetes.namespace" }}
  {{- $ := get . "$" }}
  {{- $nsValues := .gnomaTemplate }}

  {{- $_ := set $nsValues "kind" "Namespace" }}
  {{- include "gnoma-common.apiObjectHeader" . }}
{{- end }}