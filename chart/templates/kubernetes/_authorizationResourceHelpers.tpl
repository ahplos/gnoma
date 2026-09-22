{{/*
genericRoleDefinition: all ClusterRoles and Roles have this structure
*/}}
{{- define "gnoma-kubernetes.genericRoleDefinition" }}
  {{- $ := get . "$" }}
  {{- $roleValues := .gnomaTemplate }}

  {{- $_ := set $roleValues "apiVersion" ($roleValues.apiVersion | default "rbac.authorization.k8s.io/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
  {{- if $roleValues.aggregationRule }}
aggregationRule: {{ $roleValues.aggregationRule | toYaml | nindent 2 }}
  {{- end }}
  {{- if $roleValues.rules }}
rules: {{- $roleValues.rules | toYaml | nindent 0 }}
  {{- end }}
{{- end }}

{{/*
genericRoleBindingDefinition: all ClusterRoleBindings and RoleBindings have this structure
*/}}
{{- define "gnoma-kubernetes.genericRoleBindingDefinition" }}
  {{- $ := get . "$" }}
  {{- $genericRoleBindingBindingValues := .gnomaTemplate }}

  {{- $_ := set $genericRoleBindingBindingValues "apiVersion" ($genericRoleBindingBindingValues.apiVersion | default "rbac.authorization.k8s.io/v1") }}
  {{- include "gnoma-common.apiObjectHeader" . }}
roleRef: {{ $genericRoleBindingBindingValues.roleRef | toYaml | nindent 2 }}
subjects: {{ $genericRoleBindingBindingValues.subjects | toYaml | nindent 0}}
{{- end }}
