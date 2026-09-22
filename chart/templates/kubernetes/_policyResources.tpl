{{/*
  Defines templates for rendering Kubernetes workload resources, including:
  - ResourceQuota
  - LimitRange

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
  gnoma-kubernetes.resourceQuota
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $quotaValues -> Gnoma template for ResourceQuota

  ======================================

  DEFAULT KEYS
  ---
  [spec]:
    hard
    scopeSelector
    scopes

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes ResourceQuota.
*/}}
{{- define "gnoma-kubernetes.resourceQuota" }}
  {{- $ := get . "$" }}
  {{- $quotaValues := .gnomaTemplate }}

  {{- $_ := set $quotaValues "kind" "ResourceQuota" }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "hard"
                         "scopeSelector"
                         "scopes"	}}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $quotaValues "whiteList" $whiteList) }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.limitRange
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $limitValues -> Gnoma template for LimitRange

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      limits

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes LimitRange.
*/}}
{{- define "gnoma-kubernetes.limitRange" }}
  {{- $ := get . "$" }}
  {{- $limitValues := .gnomaTemplate }}

  {{- $_ := set $limitValues "kind" "LimitRange" }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "limits"	}}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $limitValues "whiteList" $whiteList) }}
{{- end }}