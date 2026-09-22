{{/*
  Defines templates for rendering Kubernetes workload resources, including:
  - Ingress
  - Service

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
  gnoma-kubernetes.ingress
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $ingressValues -> Gnoma template for Ingress

  ======================================

  HELPER KEYS
  ---
  [spec]:
    [rules]:
      - host -> .Values.gnomaDefaults.ingressHostDomain
        [paths]:
        - path -> default .Values.gnomaDefaults.ingressRulePath
          pathType -> default .Values.gnomaDefaults.ingressRulePathType
          [backend]:
            [service]:
              name -> $<OBJ_NAME>
              [port]:
                number -> $ingressValues.port | default $.Values.gnomaDefaults.port
  ---
  [spec]:
    [tls]:
    - secretName -> { if $ingressValues.allowHttp == false }

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      defaultBackend
      ingressClassName
      rules
      tls

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes Ingress.
*/}}
{{- define "gnoma-kubernetes.ingress" }}
  {{- $ := get . "$" }}
  {{- $ingressValues := .gnomaTemplate }}


  {{- $_ := set $ingressValues "kind" "Ingress" }}
  {{- $_ := set $ingressValues "apiVersion" ($ingressValues.apiVersion | default "networking.k8s.io/v1") }}
  {{- $_ := set $ingressValues "annotations" ($ingressValues.annotations | default dict) }}
  {{- if $ingressValues.allowHttp }}
    {{- $_ := set $ingressValues.annotations
                    "kubernetes.io/ingress.allow-http"
                    (eq (toString $ingressValues.allowHttp) "true" | quote)
    }}
  {{- end }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "defaultBackend"
                         "ingressClassName"	}}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $ingressValues "whiteList" $whiteList) }}
  {{- if $ingressValues.rules }}
  rules: {{- $ingressValues.rules | toYaml | nindent 4 }}
  {{- else }}
  rules:
  {{- if (not $ingressValues.host) }}
    {{- $defaultIngressHostDomain := $.Values.gnomaDefaults.ingressHostDomain }}
    {{- if (regexMatch "^[\\w]" $defaultIngressHostDomain) }}
      {{- $defaultIngressHostDomain = (printf ".%s" $defaultIngressHostDomain) }}
    {{- end }}
    {{- $_ := set $ingressValues "host" (printf "%s%s" $ingressValues.objName $defaultIngressHostDomain) }}
  {{- end }}
  - host: {{ $ingressValues.host }}
    http:
      paths:
      - path: {{ $ingressValues.path | default $.Values.gnomaDefaults.ingressRulePath }}
        pathType: {{ $ingressValues.pathType | default $.Values.gnomaDefaults.ingressRulePathType }}
        backend:
          service:
            name: {{ $ingressValues.objName }}
            port:
              number: {{ $ingressValues.port | default $.Values.gnomaDefaults.port }}
  {{- end }}
  {{- if $ingressValues.tls }}
  tls: {{ $ingressValues.tls | toYaml | nindent 4 }}
  {{- else }}
  tls:
  - secretName: {{ $ingressValues.secretName }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.service
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $svcValues -> Gnoma template for Service

  ======================================

  HELPER KEYS
  ---
  [spec]:
    selector
    ports
  ---
  [spec]:
    [ports]:
    - name- > $<OBJ_NAME>-port
      port -> .Values.gnomaDefaults.port
      targetPort
      protocol -> .Values.gnomaDefaults.protocol
  ---
  { if $svcValues.prometheus.port | .Values.usePrometheus }
  [metadata]:
    [annotations]:
      [prometheus.io/path] -> $svcValues.prometheus.path |  .Values.gnomaDefaults.prometheusPath
      [prometheus.io/port] -> $svcValues.prometheus.port | $svcValues.port
      [prometheus.io/scheme] -> $svcValues.prometheus.scheme | .Values.gnomaDefaults.prometheusScheme
      [prometheus.io/scrape] -> $svcValues.prometheus.scrape | .Values.gnomaDefaults.prometheusScrape
  {{- end }}
  ---
  { if $svcValues.prometheus.port | .Values.usePrometheus }
  [spec]:
    [ports]:
    - [name]: prometheus-port
      [port]: $svcValues.prometheus.port | .Values.gnomaDefaults.prometheusPort
      [protocol]: $svcValues.prometheus.protocol | .Values.gnomaDefaults.prometheusProtocol

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"
    "gnoma-kubernetes.prometheusAnnotations"

  ======================================

  Defines a Gnoma template for a Kubernetes Service.
*/}}
{{- define "gnoma-kubernetes.service" }}
  {{- $ := get . "$" }}
  {{- $svcValues := .gnomaTemplate }}

  {{- if or ($svcValues.prometheus).port $.Values.usePrometheus }}
    {{- include "gnoma-kubernetes.prometheusAnnotations" . }}
  {{- end }}
  {{- if or $svcValues.threeScalePort $.Values.use3Scale }}
    {{- include "gnoma-kubernetes.3ScaleAnnotations" . }}
    {{- $_ := set $svcValues "labels" ($svcValues.labels  | default dict) }}
    {{- $_ := set $svcValues.labels "discovery.3scale.net" true }}
  {{- end }}
  {{- $_ := set $svcValues "kind" "Service" }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  selector:
    gnoma.io/selector: {{ include "gnoma-common.gnomaLabels" . }}
    {{- range $key, $value := $svcValues.selector }}
    {{ $key }}: {{ $value }}
    {{- end }}
  ports:
  {{- if and $svcValues.ports $svcValues.port }}
    {{- fail "A Service cannot define both port and ports values!" }}
  {{- end }}
  {{- if $svcValues.ports }}
    {{- $svcValues.ports | toYaml | nindent 2 }}
  {{- else }}
  - name: {{ $svcValues.objName }}-port
    port: {{ $svcValues.port | default $.Values.gnomaDefaults.port }}
    {{- if or $svcValues.targetPort $svcValues.containerPort }}
    targetPort: {{ $svcValues.targetPort | default $svcValues.containerPort }}
    {{- end }}
    {{- if or $svcValues.protocol $.Values.gnomaDefaults.protocol }}
    protocol: {{ $svcValues.protocol | default $.Values.gnomaDefaults.protocol }}
    {{- end }}
  {{- end }}
  {{- if or ($svcValues.prometheus).port $svcValues.usePrometheus }}
  - name: prometheus-port
    port: {{ ($svcValues.prometheus).port | default $.Values.gnomaDefaults.prometheusPort }}
    {{- if or ($svcValues.prometheus).protocol $.Values.gnomaDefaults.prometheusProtocol }}
    protocol: {{ ($svcValues.prometheus).protocol | default $.Values.gnomaDefaults.prometheusProtocol }}
    {{- end }}
  {{- end }}
{{- end }}