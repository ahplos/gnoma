{{/*
  Defines templates for rendering Kubernetes workload resources, including:
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
  ======================================
  gnoma-kubernetes.cronjob
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $cjValues -> Gnoma template

  ======================================

  DEFAULT KEYS
    [spec]:
      concurrencyPolicy
      failedJobsHistoryLimit
      schedule
      startingDeadlineSeconds
      successfulJobsHistoryLimit
      parallelism
      ttlSecondsAfterFinished

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"
    spec:
      jobTemplate:
        "gnoma-kubernetes.jobTemplate"

  ======================================

  Defines a Gnoma template for a Kubernetes CronJob.
*/}}
{{- define "gnoma-kubernetes.cronjob" }}
  {{- $ := get . "$" }}
  {{- $cjValues := .gnomaTemplate }}

  {{- $_ := set $cjValues "kind" "CronJob" }}
  {{- $_ := set $cjValues "apiVersion" ($cjValues.apiVersion | default "batch/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "concurrencyPolicy"
                         "failedJobsHistoryLimit"
                         "schedule"
                         "startingDeadlineSeconds"
                         "successfulJobsHistoryLimit" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $cjValues "whiteList" $whiteList) }}
  jobTemplate: {{ include "gnoma-kubernetes.jobTemplate" . | indent 4 }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.deployment
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for Deployment

  ======================================

  HELPER KEYS
  ---
  [spec]:
    revisionHistoryLimit -> .Values.gnomaDefaults.deploymentRevisionHistoryLimit
  ---
  [spec]:
    [strategy]:
      [type]: strategyType
      [rollingUpdate { if $deployValues.strategyType == "RollingUpdate" } ]:
        rollingUpdateMaxSurge -> .Values.gnomaDefaults.rollingUpdateMaxSurge
        rollingUpdateMaxUnavailable -> .Values.gnomaDefaults.rollingUpdateMaxUnavailable

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      minReadySeconds
      progressDeadlineSeconds
      replicas

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"
    spec:
      template:
        "gnoma-kubernetes.podTemplate"

  ======================================

  Defines a Gnoma template for a Kubernetes Deployment.
*/}}
{{- define "gnoma-kubernetes.deployment" }}
  {{- $ := get . "$" }}
  {{- $deployValues := .gnomaTemplate }}

  {{- $_ := set $deployValues "kind" "Deployment" }}
  {{- $_ := set $deployValues "apiVersion" ($deployValues.apiVersion | default "apps/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "minReadySeconds"
                         "progressDeadlineSeconds"
                         "replicas" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $deployValues "whiteList" $whiteList) }}
  revisionHistoryLimit: {{ ($deployValues.revisionHistoryLimit | default $.Values.gnomaDefaults.deploymentRevisionHistoryLimit) | int }}
  {{- include "gnoma-kubernetes.labelSelector" . | indent 2 }}
  {{- if $deployValues.strategyType }}
  strategy:
    {{- if (eq $deployValues.strategyType "RollingUpdate") }}
    rollingUpdate:
      maxSurge: {{ $deployValues.rollingUpdateMaxSurge | default $.Values.gnomaDefaults.rollingUpdateMaxSurge }}
      maxUnavailable: {{ $deployValues.rollingUpdateMaxUnavailable | default $.Values.gnomaDefaults.rollingUpdateMaxUnavailable }}
    {{- end }}
    type: {{ $deployValues.strategyType }}
  {{- end }}
  {{- $args := dict "$" $ "gnomaTemplate" $deployValues }}
  template: {{ include "gnoma-kubernetes.podTemplate" $args | indent 4 }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.horizontalPodAutoscaler
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $hpaValues -> Gnoma template for HorizontalPodAutoscaler

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      behavior
      maxReplicas
      minReplicas
      scaleTargetRef
        apiVersion -> / "apps/v1"
        kind -> / "Deployment"
        name -> / $<OBJ_NAME>
    ---
    [spec]:
      [metrics]:
      - type:
        [<type>]:
          container
          describedObject
          name
          metric
          target

  ======================================

  Gnoma SUPPORTING TEMPLATES
  ---
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes HorizontalPodAutoscaler.

  Defining hpa metrics in the Gnoma template:

    metrics:
    - type: <type>
      name: <name>
      target:
        <target def per hpa>

  Will generate in the final YAML:

  spec:
    metrics:
    - type: <Type> # note the title case
      <type>:
        name: <name>
        target:
          <target def per hpa>

  The Gnoma template only require defining hpa the type, and Gnoma template will generate the correct
  YAML structure.
*/}}
{{- define "gnoma-kubernetes.horizontalPodAutoscaler" }}
  {{- $ := get . "$" }}
  {{- $hpaValues := .gnomaTemplate }}

  {{- $_ := set $hpaValues "kind" "HorizontalPodAutoscaler" }}
  {{- $_ := set $hpaValues "apiVersion" ($hpaValues.apiVersion | default "autoscaling/v2") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "behavior"
                         "maxReplicas"
                         "metrics"
                         "minReplicas" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $hpaValues "whiteList" $whiteList) }}
  scaleTargetRef:
    apiVersion: {{ ($hpaValues.scaleTargetRef).apiVersion | default "apps/v1"  }}
    kind: {{ ($hpaValues.scaleTargetRef).kind | default "Deployment" }}
    name: {{ ($hpaValues.scaleTargetRef).name | default $hpaValues.objName }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.job
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $jobValues -> Gnoma template for Job

  ======================================

  Gnoma SUPPORTING TEMPLATES
  ---
    "gnoma-common.apiObjectHeader"
    "gnoma-kubernetes.jobSpec"

  ======================================

  Defines a Gnoma template for a Kubernetes Job.
*/}}
{{- define "gnoma-kubernetes.job" }}
  {{- $ := get . "$" }}
  {{- $jobValues := .gnomaTemplate }}

  {{- $_ := set $jobValues "kind" "Job" }}
  {{- $_ := set $jobValues "apiVersion" ($jobValues.apiVersion | default "batch/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
  {{- include "gnoma-kubernetes.jobSpec" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.pod
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $podValues -> Gnoma template for Pod

  ======================================

  Gnoma SUPPORTING TEMPLATES
  ---
    "gnoma-common.apiObjectHeader"
    "gnoma-kubernetes.podTemplate"

  ======================================

  Defines a Gnoma template for a Kubernetes Pod.
*/}}
{{- define "gnoma-kubernetes.pod" }}
  {{- $ := get . "$" }}
  {{- $podValues := .gnomaTemplate }}

  {{- $_ := set $podValues "kind" "Pod" }}
  {{- include "gnoma-common.apiObjectHeader" . }}
  {{- include "gnoma-kubernetes.podTemplate" . }}
{{- end }}

{{/*
  ======================================
  gnoma-kubernetes.statefulset
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for StatefulSet

  ======================================

  DEFAULT KEYS:
  ---
   [spec]:
      minReadySeconds
      ordinals
      persistentVolumeClaimRetentionPolicy
      podManagementPolicy
      replicas
      revisionHistoryLimit
      updateStrategy
      volumeClaimTemplates

  ======================================

  Gnoma SUPPORTING TEMPLATES
  ---
    "gnoma-common.apiObjectHeader"
    spec:
      "gnoma-kubernetes.labelSelector"
      template:
        "gnoma-kubernetes.podTemplate"

  ======================================

  Defines a Gnoma template for a Kubernetes StatefulSet.
*/}}
{{- define "gnoma-kubernetes.statefulset" }}
  {{- $ := get . "$" }}
  {{- $stsValues := .gnomaTemplate }}

  {{- $_ := set $stsValues "kind" "StatefulSet" }}
  {{- $_ := set $stsValues "apiVersion" ($stsValues.apiVersion | default "apps/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "minReadySeconds"
                         "ordinals"
                         "persistentVolumeClaimRetentionPolicy"
                         "podManagementPolicy"
                         "replicas"
                         "revisionHistoryLimit"
                         "updateStrategy"
                         "volumeClaimTemplates" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $stsValues "whiteList" $whiteList) }}
  {{- include "gnoma-kubernetes.labelSelector" . | indent 2 }}
  template:
  {{- $args := dict "$" $ "gnomaTemplate" $stsValues }}
  {{- include "gnoma-kubernetes.podTemplate" $args | indent 4 }}
{{- end }}


{{/*
  ======================================
  gnoma-kubernetes.daemonset
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for DaemonSet

  ======================================

  DEFAULT KEYS:
  ---
   [spec]:
      minReadySeconds
      revisionHistoryLimit
      updateStrategy

  ======================================

  Gnoma SUPPORTING TEMPLATES
  ---
    "gnoma-common.apiObjectHeader"
    spec:
      "gnoma-kubernetes.labelSelector"
      template:
        "gnoma-kubernetes.podTemplate"

  ======================================

  Defines a Gnoma template for a Kubernetes DaemonSet.
*/}}
{{- define "gnoma-kubernetes.daemonset" }}
  {{- $ := get . "$" }}
  {{- $dsValues := .gnomaTemplate }}

  {{- $_ := set $dsValues "kind" "DaemonSet" }}
  {{- $_ := set $dsValues "apiVersion" ($dsValues.apiVersion | default "apps/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "minReadySeconds"
                         "revisionHistoryLimit"
                         "updateStrategy" }}
  {{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $dsValues "whiteList" $whiteList) }}
  {{- include "gnoma-kubernetes.labelSelector" . | indent 2 }}
  template:
  {{- $args := dict "$" $ "gnomaTemplate" $dsValues }}
  {{- include "gnoma-kubernetes.podTemplate" $args | indent 4 }}
{{- end }}