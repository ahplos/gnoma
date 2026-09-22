{{/*
  Helper templates for rendering Kubernetes workload resources, including:
  - CronJob
  - Deployment
  - HorizontalPodAutoscaler
  - Job
  - StatefulSet

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
General k8s selector definition.
*/}}
{{- define "gnoma-kubernetes.labelSelector" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}
selector:
  matchExpressions:
  - key: gnoma.io/selector
    operator: Exists
  {{- if ($template.selector).matchExpressions }}
    {{- $template.selector.matchExpressions | toYaml | indent 2 }}
  {{- end }}
  matchLabels:
    gnoma.io/selector: {{ include "gnoma-common.gnomaLabels" . }}
  {{- if ($template.selector).matchLabels }}
    {{- $template.selector.matchLabels | toYaml | indent 4 }}
  {{- end }}
{{- end }}

{{/*
Defines the basic structure of a jobTemplate and the keys under it.

  "gnoma-common.metadata"
  [metadata]:
  ---
  "gnoma-kubernetes.jobSpec"
  [spec]:
    [template]:
*/}}
{{- define "gnoma-kubernetes.jobTemplate" }}
  {{- $ := get . "$" }}
  {{- $jobValues := .gnomaTemplate }}

  {{- include "gnoma-common.metadata" . }}
  {{- include "gnoma-kubernetes.jobSpec" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.podTemplate
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $jobValues -> Gnoma template values

  ======================================

  DEFAULT KEYS
  [spec]:
    [template]:
        activeDeadlineSeconds
        backoffLimit
        completionMode
        completions
        manualSelector
        parallelism
        podFailurePolicy
        restartPolicy -> "Never"
        suspend
        ttlSecondsAfterFinished

  "gnoma-kubernetes.podTemplate"
  [spec]:
    [template]:
      [spec]:

Defines the spec.template portion of a Job or JobTemplate (CronJob).


*/}}
{{- define "gnoma-kubernetes.jobSpec" }}
  {{- $ := get . "$" }}
  {{- $jobValues := .gnomaTemplate }}
spec:
  {{- $whiteList := list "activeDeadlineSeconds"
                         "backoffLimit"
                         "backoffLimitPerIndex"
                         "completionMode"
                         "completions"
                         "manualSelector"
                         "maxFailedIndexes"
                         "parallelism"
                         "podFailurePolicy"
                         "podReplacementPolicy"
                         "selector"
                         "successPolicy"
                         "suspend"
                         "ttlSecondsAfterFinished" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $jobValues "whiteList" $whiteList) }}
  template:
  {{- $_ := set $jobValues "restartPolicy" ($jobValues.restartPolicy | default "Never") }}
  {{- $args := dict "$" $ "gnomaTemplate" $jobValues }}
  {{- include "gnoma-kubernetes.podTemplate" $args | indent 4 }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.podTemplate
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $podValues -> Gnoma template values

  ======================================

  HELPER KEYS
  ---
  containers
  ephemeralContainers
  imagePullSecret
  imagePullSecrets
  initContainers
  securityContext
  useLegacyPodSecurityContextDefault [NOTE: in case of running in older version of k8s]

  ======================================

  DEFAULT KEYS
    activeDeadlineSeconds
    affinity
    automountServiceAccountToken
    dnsConfig
    dnsPolicy
    enableServiceLinks
    hostAliases
    hostIPC
    hostNetwork
    hostPID
    hostname
    nodeName
    nodeSelector
    os
    overhead
    preemptionPolicy
    priority
    priorityClassName
    readinessGates
    restartPolicy
    runtimeClassName
    schedulerName
    serviceAccount
    serviceAccountName
    setHostnameAsFQDN
    shareProcessNamespace
    subdomain
    terminationGracePeriodSeconds
    tolerations
    topologySpreadConstraints
    volumes

  ======================================

  Generates a PodTemplate.  Used by CronJobs, Deployments, StatefulSets, Pods, and Jobs.
*/}}
{{- define "gnoma-kubernetes.podTemplate" }}
  {{- $ := get . "$" }}
  {{- $podValues := .gnomaTemplate }}

  {{- include "gnoma-common.metadata" . }}
spec:
  {{- if or $podValues.containers (not (eq $podValues.templateName "podTemplate")) }}
  containers:
    {{- $containers := prepend ($podValues.containers | default list) $podValues }}
    {{- include "gnoma-kubernetes.containers" (dict "$" $ "podValues" $podValues "containers" $containers) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.ephemeralContainers }}
  ephemeralContainers:
    {{- include "gnoma-kubernetes.containers" (dict "$" $ "podValues" $podValues "containers" $podValues.ephemeralContainers) | trim | nindent 2 }}
  {{- end }}
  {{- $_ := set $podValues "imagePullSecrets" ($podValues.imagePullSecrets | default $.Values.gnomaDefaults.imagePullSecrets) }}
  {{- $_ := set $podValues "imagePullSecret" ($podValues.imagePullSecret | default $.Values.gnomaDefaults.imagePullSecret) }}
  {{- if $podValues.imagePullSecrets }}
  imagePullSecrets: {{ $podValues.imagePullSecrets | toYaml | nindent 2 }}
  {{- else if $podValues.imagePullSecret }}
  imagePullSecrets:
  - name: {{ $podValues.imagePullSecret }}
  {{- else }}
  imagePullSecrets: []
  {{- end }}
  {{- if $podValues.initContainers }}
  initContainers:
    {{- include "gnoma-kubernetes.containers" (dict "$" $ "podValues" $podValues "containers" $podValues.initContainers) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.securityContext }}
  securityContext: {{ $podValues.securityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  {{- end }}

  {{- $whiteList := list  "activeDeadlineSeconds"
                          "affinity"
                          "automountServiceAccountToken"
                          "dnsConfig"
                          "dnsPolicy"
                          "enableServiceLinks"
                          "hostAliases"
                          "hostIPC"
                          "hostNetwork"
                          "hostPID"
                          "hostname"
                          "nodeName"
                          "nodeSelector"
                          "os"
                          "overhead"
                          "preemptionPolicy"
                          "priority"
                          "priorityClassName"
                          "readinessGates"
                          "restartPolicy"
                          "runtimeClassName"
                          "schedulerName"
                          "serviceAccount"
                          "serviceAccountName"
                          "setHostnameAsFQDN"
                          "shareProcessNamespace"
                          "subdomain"
                          "terminationGracePeriodSeconds"
                          "tolerations"
                          "topologySpreadConstraints"
                          "volumes" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $podValues "whiteList" $whiteList) }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.podTemplate
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $podValues -> Gnoma template values
    $containers -> list of container definitions in pod; can render containers, initContainers, ephemeralCotainers, etc.

  ======================================

  HELPER KEYS
  ---
    image -> .Values.gnomaDefaults.image
    imagePullPolicy -> .Values.gnomaDefaults.imagePullPolicy
    limitsCpu
    limitsMemory
    name -> $<OBJ_NAME>
    prometheus.port
    prometheus.protocol
    resources
    securityContext
    projectedVolumes
    usePrometheus

  ======================================

  DEFAULT KEYS
    args
    command
    env
    envFrom
    lifecycle
    livenessProbe
    readinessProbe
    startupProbe
    stdin
    stdinOnce
    terminationMessagePath
    terminationMessagePolicy
    tty
    volumeDevices
    volumeMounts
    workingDir

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-kubernetes.envFrom"
    "gnoma-kubernetes.projectedVolumes"

  ======================================

  Generates a PodTemplate.  Used by CronJobs, Deployments, StatefulSets, Pods, and Jobs.
*/}}
{{- define "gnoma-kubernetes.containers" }}
{{- $ := get . "$" }}
{{- $podValues := .podValues }}
{{- $containers := .containers }}

{{- $whiteList := list "args"
                       "command"
                       "env"
                       "envFrom"
                       "lifecycle"
                       "livenessProbe"
                       "readinessProbe"
                       "startupProbe"
                       "stdin"
                       "stdinOnce"
                       "terminationMessagePath"
                       "terminationMessagePolicy"
                       "tty"
                       "volumeDevices"
                       "volumeMounts"
                       "workingDir" }}
{{- range $index, $containerVals := $containers }}
- {{ if or (eq $index 0) $containerVals.name -}}
  name: {{ $containerVals.name | default $containerVals.objName }}
  {{ end -}}
  image: {{ $containerVals.image | default $.Values.gnomaDefaults.image }}
  imagePullPolicy: {{ $containerVals.imagePullPolicy | default $.Values.gnomaDefaults.imagePullPolicy }}
  {{- if or $containerVals.ports $containerVals.port $.Values.gnomaDefaults.port $containerVals.usePrometheus }}
  ports:
    {{- if $containerVals.ports }}
      {{- $containerVals.ports | toYaml | nindent 2 }}
    {{- else if or $containerVals.port $.Values.gnomaDefaults.port }}
  - name: default-port
    containerPort: {{ $containerVals.containerPort | default $containerVals.targetPort | default $containerVals.port | default $.Values.gnomaDefaults.port }}
    protocol: {{ $containerVals.protocol | default $.Values.gnomaDefaults.protocol }}
    {{- end }}
    {{- if or ($containerVals.prometheus).port (and $containerVals.usePrometheus $.Values.gnomaDefaults.prometheusPort) }}
  - name: prometheus-port
    containerPort: {{ ($containerVals.prometheus).port | default $.Values.gnomaDefaults.prometheusPort }}
    protocol: {{ ($containerVals.prometheus).protocol | default ($.Values.gnomaDefaults.prometheusProtocol | default $.Values.gnomaDefaults.protocol) }}
    {{- end }}
  {{- end }}
  resources:
    limits:
      {{- if ($containerVals.resources).limits }}
        {{- range $limit, $value := ($containerVals.resources).limits }}
      {{ $limit }}: {{ $value }}
        {{- end }}
      {{- else if or $containerVals.limitsCpu $containerVals.limitsMemory }}
        {{- if $containerVals.limitsCpu }}
      cpu: {{ $containerVals.limitsCpu }}
        {{- end }}
        {{- if $containerVals.limitsMemory }}
      memory: {{ $containerVals.limitsMemory }}
        {{- end }}
      {{- else }}
        {{- print " {}" }}
      {{- end }}
    requests:
      {{- if ($containerVals.resources).requests }}
        {{- range $request, $value := ($containerVals.resources).requests }}
      {{ $request }}: {{ $value }}
        {{- end }}
      {{- else if or $containerVals.requestsCpu $containerVals.requestsMemory }}
        {{- if $containerVals.requestsCpu }}
      cpu: {{ $containerVals.requestsCpu }}
        {{- end }}
        {{- if $containerVals.requestsMemory }}
      memory: {{ $containerVals.requestsMemory }}
        {{- end }}
      {{- else }}
        {{- print " {}" }}
      {{- end }}
  {{- if $containerVals.containerSecurityContext }}
  securityContext: {{ $containerVals.containerSecurityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
  {{- end }}
  {{- if $containerVals.projectedVolumes }}
    {{- include "gnoma-kubernetes.projectedVolumes" (dict "$" $ "podValues" $podValues "containerVals" $containerVals) }}
  {{- end }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $podValues "whiteList" $whiteList) }}
{{- end }}
{{- end }}