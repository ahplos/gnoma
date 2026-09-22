{{/*
  ======================================
  gnoma-kubernetes.initGnomaDefaults
  ======================================

  Initialize gnomaDefaults for gnoma-kubernetes.  Sets the following defaults if they aren't already set in a *values.yaml:

  - deploymentRevisionHistoryLimit -> 0
  - port -> "8080"
  - protocol -> "TCP"
  - ingressRulePath -> "/"
  - ingressRulePathType -> "Prefix"

  Prometheus and 3Scale defaults are provided:

  - prometheusPort -> "9090"
  - prometheusPath -> "/metrics"
  - prometheusScheme -> "https"
  - prometheusScrape -> "false"
  - prometheusProtocol -> "TCP"

  - 3ScaleScheme -> "https"
*/}}
{{- define "gnoma-kubernetes.initGnomaDefaults" }}
  {{- $ := . }}

  {{- $_ := set $.Values.gnomaDefaults "annotations" ($.Values.gnomaDefaults.annotations | default dict) }}
  {{- $_ := set $.Values.gnomaDefaults "labels" ($.Values.gnomaDefaults.labels | default dict) }}

  {{- $_ := set $.Values.gnomaDefaults "deploymentRevisionHistoryLimit" ($.Values.gnomaDefaults.deploymentRevisionHistoryLimit | default 0) }}

  {{- $_ := set $.Values.gnomaDefaults "imagePullPolicy" ($.Values.gnomaDefaults.imagePullPolicy | default "IfNotPresent") }}

  {{- $_ := set $.Values.gnomaDefaults "port" ($.Values.gnomaDefaults.port | default "8080") }}
  {{- $_ := set $.Values.gnomaDefaults "protocol" ($.Values.gnomaDefaults.protocol | default "TCP") }}

  {{- $_ := set $.Values.gnomaDefaults "ingressRulePath" ($.Values.gnomaDefaults.ingressRulePath | default "/") }}
  {{- $_ := set $.Values.gnomaDefaults "ingressRulePathType" ($.Values.gnomaDefaults.ingressRulePathType | default "Prefix") }}

  {{- $_ := set $.Values.gnomaDefaults "prometheusPort" ($.Values.gnomaDefaults.prometheusPort | default "9090") }}
  {{- $_ := set $.Values.gnomaDefaults "prometheusPath" ($.Values.gnomaDefaults.prometheusPath | default "/metrics") }}
  {{- $_ := set $.Values.gnomaDefaults "prometheusScheme" ($.Values.gnomaDefaults.prometheusScheme | default "https") }}
  {{- $_ := set $.Values.gnomaDefaults "prometheusScrape" ($.Values.gnomaDefaults.prometheusScrape | default "false") }}
  {{- $_ := set $.Values.gnomaDefaults "prometheusProtocol" ($.Values.gnomaDefaults.prometheusProtocol | default "TCP") }}

  {{- $_ := set $.Values.gnomaDefaults "3ScaleScheme" ((get $.Values.gnomaDefaults "3ScaleScheme") | default "https") }}
{{- end }}

{{/*
Service Prometheus Annotations definition.  Add the following annotations:

  prometheus.io/path -> .Values.gnomaDefaults.prometheusPath
  prometheus.io/port -> .Values.gnomaDefaults.port
  prometheus.io/scheme -> .Values.gnomaDefaults.scheme
  prometheus.io/scrape -> .Values.gnomaDefaults.scrape
*/}}
{{- define "gnoma-kubernetes.prometheusAnnotations" }}
  {{- $ := get . "$" }}
  {{- $svcValues := .gnomaTemplate }}

  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}

  {{- if or ($svcValues.prometheus).path $.Values.gnomaDefaults.prometheusPath }}
    {{- $_ := set $svcValues.annotations "prometheus.io/path" ($svcValues.prometheus.path | default $.Values.gnomaDefaults.prometheusPath) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).port $.Values.gnomaDefaults.prometheusPort }}
    {{- $_ := set $svcValues.annotations "prometheus.io/port" ($svcValues.prometheus.port | default $svcValues.port) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scheme $.Values.gnomaDefaults.prometheusScheme }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scheme" ($svcValues.prometheus.scheme | default $.Values.gnomaDefaults.prometheusScheme) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scrape $.Values.gnomaDefaults.prometheusScrape }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scrape" ($svcValues.prometheus.scrape | default $.Values.gnomaDefaults.prometheusScrape) }}
  {{- end }}
{{- end }}

{{/*
Service Prometheus 3Scale definition.  Adds the following annotations:

  discovery.3scale.net/path -> .Values.gnomaDefaults.port
  discovery.3scale.net/port -> .Values.gnomaDefaults.3ScalePath
  discovery.3scale.net/scheme -> .Values.gnomaDefaults.3ScalePath
*/}}
{{- define "gnoma-kubernetes.3ScaleAnnotations" }}
  {{- $ := get . "$" }}
  {{- $svcValues := .gnomaTemplate }}

  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.gnomaDefaults.port) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default (get $.Values.gnomaDefaults "3ScalePath")) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default (get $.Values.gnomaDefaults "3ScaleScheme")) }}
{{- end }}