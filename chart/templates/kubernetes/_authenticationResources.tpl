{{/*
  ======================================
  gnoma-kubernetes.serviceAccount
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $deployValues -> Gnoma template for ServiceAccount

  ======================================

  HELPER KEYS
  ---
    imagePullSecrets:
    - [name]:
    secrets:
    - [name]:


  ======================================

  DEFAULT KEYS
  ---
    automountServiceAccountToken

  ======================================

  Gnoma SUPPORTING TEMPLATES:
    "gnoma-common.apiObjectHeader"

  ======================================

  Defines a Gnoma template for a Kubernetes ServiceAccount.
*/}}
{{- define "gnoma-kubernetes.serviceAccount" }}
{{- $ := get . "$" }}
{{- $svcAcctValues := .gnomaTemplate }}

{{- $_ := set $svcAcctValues "kind" "ServiceAccount" }}
{{- include "gnoma-common.apiObjectHeader" . }}
{{- $whiteList := list "automountServiceAccountToken"	}}
{{- include "gnoma-common.outputToYaml" (dict "$" $ "gnomaTemplate" $svcAcctValues "whiteList" $whiteList) }}
{{- if $svcAcctValues.imagePullSecrets }}
imagePullSecrets:
{{- range $imagePullSecret := $svcAcctValues.imagePullSecrets  }}
- name: {{ $imagePullSecret }}
{{- end }}
{{- end }}
{{- if $svcAcctValues.secrets }}
secrets:
{{- range $secret := $svcAcctValues.secrets  }}
- name: {{ $secret }}
{{- end }}
{{- end }}
{{- end }}
