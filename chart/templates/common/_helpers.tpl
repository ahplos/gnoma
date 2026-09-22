{{/*
  ======================================
  gnoma-kubernetes.apiObjectHeader
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template

  ======================================

  DEFAULT KEYS
    apiVersion
    kind

  ======================================

  Gnoma SUPPORTING TEMPLATES:
  "gnoma-common.metadata"

  ======================================

  General header for a Kubernetes compliant resource.
*/}}
{{- define "gnoma-common.apiObjectHeader" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}

apiVersion: {{ $template.apiVersion | default "v1" }}
kind: {{ required "Kubernetes API objects require a \"kind\"" $template.kind }}
  {{- if $template.metadata }}
metadata:
    {{ toYaml $template.metadata | nindent 2 }}
  {{- else }}
    {{- include "gnoma-common.metadata" . }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.apiMetadata
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template

  ======================================

  DEFAULT KEYS
    [metadata]:
      annotations
      labels
      name
      namespace

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.labels"

  ======================================

  General header for a Kubernetes compliant resource metadata.
*/}}
{{- define "gnoma-common.metadata" }}
  {{- $ := get . "$" }}
  {{- $metadataValues := .gnomaTemplate }}
metadata:
  {{- $_ := set $metadataValues "annotations" (mergeOverwrite ($metadataValues.annotations | default dict) ($.Values.gnomaDefaults.annotations | default dict)) }}
  {{- if $metadataValues.annotations }}
  annotations:
    {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- $_ := set $metadataValues "labels" (mergeOverwrite ($metadataValues.labels | default dict) ($.Values.gnomaDefaults.labels | default dict)) }}
  labels:
    {{- include "gnoma-common.labels" (dict "$" $ "labels" $metadataValues.labels) }}
    {{- $_ := set $metadataValues.labels "gnoma.io/selector" (include "gnoma-common.gnomaLabels" .) }}
    {{- range $key, $value := $metadataValues.labels }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.objName }}
  namespace: {{ $metadataValues.namespace | default $metadataValues.tplGnomaDefs.NAME_SPACE }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.labels
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template

  ======================================

  HELPER KEYS
  ---
    helm.sh/chart -> .Chart.Name-.Chart.Version
    app.kubernetes.io/instance -> .Release.Name
    app.kubernetes.io/managed-by -> .Release.Service
    app.kubernetes.io/version -> .Chart.AppVersion
    gnomaSelector -> $template.objName

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.gnomaLabels"

  ======================================

  Generates some default labels for a Kubernetes compliant resource based on the values in Chart.yaml.
*/}}
{{- define "gnoma-common.labels" }}
  {{- $ := get . "$" }}
  {{- $labels := .labels }}

  {{- $_ := set $labels "app.kubernetes.io/instance" (toString $.Release.Name) }}
  {{- $_ := set $labels "app.kubernetes.io/managed-by" $.Release.Service }}

  {{- if $.Chart.AppVersion }}
    {{- $_ := set $labels "app.kubernetes.io/version" $.Chart.AppVersion }}
  {{- end }}

  {{- $_ := set $labels "helm.sh/chart" (printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-") }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.gnomaLabels
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template

  ======================================

  HELPER KEYS
  ---
    gnomaSelector -> $template.objName

  ======================================

  Generates a selector label, gnoma.io/selector.
*/}}
{{- define "gnoma-common.gnomaLabels" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}

  {{- $selector := $template.gnomaSelector | default (regexReplaceAll "[^\\w-.]" $template.objName "-") }}
  {{- if (gt (len $selector) 63 ) }}
    {{- $selector = $selector | trunc 48 | trimSuffix "-"}}
    {{- $selectorSuffix := derivePassword 1 "long" $selector $selector "gnoma.org"  }}
    {{- $selectorSuffix = (regexReplaceAll "[^\\w-.]"  $selectorSuffix  "_" )}}
    {{- $selectorSuffix = (regexReplaceAll "[-_.]$"  $selectorSuffix  "Z" )}}
    {{- $selector = printf "%s-%s" $selector $selectorSuffix }}
  {{- end }}

  {{- $selector }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.outputToYaml
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template
    $whiteList -> list of whitelisted keys output to YAML if defined in the $.Values map

  ======================================

  This is a catch-all that renders all extraneous key/values pairs that don't have helper keys or structures.
  Checks the template values for each resource's whiteList, and if it exists renders it properly.
*/}}
{{- define "gnoma-common.outputToYaml" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}
  {{- $whiteList := .whiteList }}
  {{- $indent := quote .indent | default 2 | int }}

  {{- include "gnoma-common.setTemplateDefaultValue" . }}

  {{- range $key, $value := $template }}
    {{- if or (has $key $whiteList) (empty $whiteList) }}
      {{- if (kindIs "map" $value) }}
        {{- $key | nindent $indent }}:
        {{- $value | toYaml | nindent (int (add $indent 2)) }}
      {{- else if (kindIs "slice" $value) }}
        {{- $key | nindent $indent }}:
        {{- $value | toYaml | nindent $indent }}
      {{- else if kindIs "string" $value }}
        {{- $key | nindent $indent }}: {{ $value | quote }}
      {{- else }}
        {{- $key | nindent $indent }}: {{ $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.setTemplateDefaultValue
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma template
    $whiteList -> list of whitelisted keys to set default value, if it exists

  ======================================

  Support function for the outputToYaml function.  Assigns a value for anything in the whiteList
  that is empty and has n gnomaDefault value defined.
*/}}
{{- define "gnoma-common.setTemplateDefaultValue" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}
  {{- $whiteList := .whiteList }}

  {{- range $key := $whiteList }}
    {{- if not (hasKey $template $key) }}
      {{- $defaultValue := get $.Values.gnomaDefaults $key }}
      {{- if $defaultValue }}
        {{- $_ := set $template $key $defaultValue }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.kubeObjectMetadata
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> Gnoma free form template

  ======================================

  Supports defining metadata for a free form Kubernetes compatible resource.
*/}}
{{- define "gnoma-common.kubeObjectMetadata" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}

  {{- $_ := set $template.template "apiVersion" ($template.template.apiVersion | default $template.apiVersion | default "v1") }}
  {{- $_ := set $template.template "kind" ($template.template.kind | default $template.kind) }}
  {{- $_ := required "Kubernetes API objects require a \"kind\"" $template.template.kind }}

  {{- $metadata := $template.template.metadata | default dict }}
  {{- $_ := set $template.template "metadata" $metadata }}
  {{- $_ := set $metadata "name" ($metadata.name | default $template.objName | default $.Values.gnomaDefaults.objName) }}
  {{- $_ := set $template "objName" ($template.objName | default $metadata.name) }}
  {{- $_ := set $metadata "namespace" ($metadata.namespace | default $template.namespace | default $.Release.Namespace) }}

  {{- $_ := set $metadata "annotations" ($metadata.annotations | default dict) }}
  {{- $_ := set $template "annotations" ($template.annotations | default dict) }}
  {{- $_ := set $metadata "annotations" (merge $metadata.annotations $template.annotations) }}

  {{- $_ := set $metadata "labels" ($metadata.labels | default dict) }}
  {{- include "gnoma-common.labels" (dict "$" $ "labels" $metadata.labels)  }}
  {{- $_ := set $metadata.labels "gnoma.io/selector" (include "gnoma-common.gnomaLabels" .) }}
  {{- $_ := set $template "labels" ($template.labels | default dict) }}
  {{- $_ := set $metadata "labels" (merge $metadata.labels $template.labels) }}
{{- end }}