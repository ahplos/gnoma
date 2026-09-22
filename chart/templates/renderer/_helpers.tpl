# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  gnoma-renderer.initGnomaRenderer
  ======================================

  PARAMETERS LIST:
    $ -> root of chart

  ======================================

  Initializes the Gnoma Renderer.

  1. Ensures all lists and dictionaries Gnoma Chart uses are non-null with default, empty collections.
  2. Merges global profiles ($.Values.global.gnomaProfiles) into the currently rendered chart's active profiles
     i. The chart will fail if gnomaProfiles is not a list type
  3. Gathers all defaults used in processing the chart.
  2. Initilizes some Gnoma chart internal data for processing purposes (gnoma-renderer.gatherGnomaDefaults)
  3. Sets the default, Gnoma template prefix.
    i. If not defined by the end user, assumes "gnoma-kubernetes"; i.e. if the templateName
       of a template is "bar", Gnoma Chart will assume the Helm template to call is "gnoma-kubernetes.bar"
  4. Defines internal Gnoma Chart values for parsing.
*/}}
{{- define "gnoma-renderer.initGnomaRenderer" }}
  {{- $ := . }}

  {{- $_ := set $.Values "global" ($.Values.global | default dict) }}

  {{- $_ := set $.Values "gnomaDefaults" ($.Values.gnomaDefaults | default dict) }}
  {{- $_ := set $.Values.gnomaDefaults "objName" ($.Values.gnomaDefaults.objName | default $.Release.Name) }}

  {{- $_ := set $.Values "gnomaDefs" ($.Values.gnomaDefs | default dict) }}
  {{- $_ := set $.Values "skippedTemplates" list }}

  {{- $_ := set $.Values.gnomaDefaults "templatesChart" ($.Values.gnomaDefaults.templatesChart | default "gnoma-kubernetes") }}

  {{- if or $.Values.gnomaProfiles $.Values.global.gnomaProfiles }}
    {{- $_ := set $.Values "gnomaProfiles" ($.Values.global.gnomaProfiles | default $.Values.gnomaProfiles | default list) }}
    {{- $_ := set $.Values "gnomaProfiles" (compact $.Values.gnomaProfiles) }}
    {{- if not (kindIs "slice" $.Values.gnomaProfiles) }}
      {{- fail (printf "Profiles must be specified as an array: %s" $.Values.gnomaProfiles) }}
    {{- end }}
  {{- end }}

  {{- include "gnoma-renderer.gatherGnomaDefaults" $ }}

  {{- include "gnoma-kubernetes.initGnomaDefaults" $ }}

  {{- include "gnoma-renderer.setInternalConstants" $ }}
{{- end }}

{{/*
  ======================================
  gnoma-renderer.setInternalConstants
  ======================================
*/}}
{{- define "gnoma-renderer.setInternalConstants" }}
  {{- $_ := set $.Values "__EC_EMPTY_LIST" list }}
  {{- $_ := set $.Values "__EC_EMPTY_DICT" list }}

  {{- $_ := set $.Values "__EC_RESULT_DICT" dict }}

  {{- $_ := set $.Values "__EC_DEPTH" "__EC_DEPTH" }}
  {{- $_ := set $.Values "__EC_MAX_DEPTH" 15 }}
  {{- $_ := set $.Values "__EC_ORIG_VALUE_KEY" "__EC_ORIG_VALUE_KEY" }}

  {{- $_ := set $.Values "__EC_CONFIG_PREFIX" "$<BASE64|" }}
  {{- $_ := set $.Values "__EC_CONFIG_PREFIX" "$<CONFIG|" }}

  {{- $_ := set $.Values "__EC_FILE_PREFIX" "$<FILE|" }}
  {{- $_ := set $.Values "__EC_FILE_PREFIX" "$<CONFIG_FILE|" }}
  {{- $_ := set $.Values "__EC_FILE_PREFIX" "$<SECRET_CONFIG_FILE|" }}
  {{- $_ := set $.Values "__EC_GLOB_PREFIX" "$<GLOB|" }}
  {{- $_ := set $.Values "__EC_SECRET_GLOB_PREFIX" "$<SECRET_GLOB|" }}
  {{- $_ := set $.Values "__EC_IMPORT_FILES_PREFIX_REGEX" `\$<(?:FILE|CONFIG_FILE|SECRET_CONFIG_FILE|GLOB|SECRET_GLOB)\|` }}

  {{- $_ := set $.Values "__EC_ESCAPED_REGEX" `[\\][\$][<]` }}
  {{- $_ := set $.Values "__EC_UNESCAPED_REGEX" "$<" }}

  {{- $_ := set $.Values "__EC_PARAM_REGEX" `(?:^|[^\\])\$<(?:([\w]+)[|])?([\w]+?(?:[-][\w]+?)*)>` }}

  {{- $_ := set $.Values "__EC_OBJNAME_REGEX" "[a-z0-9]([-a-z0-9]*[a-z0-9])?([.][a-z0-9]([-a-z0-9]*[a-z0-9])?)*" }}
  {{- $_ := set $.Values "__EC_PROFILE_REGEX" "[A-Z0-9]+(?:[._][A-Z0-9]+)*" }}
{{- end }}

{{/*
  ======================================
  gnoma-renderer.gatherGnomaDefaults
  ======================================

  PARAMETERS LIST:
    $ -> root of chart

  ======================================

  Collects the defaults Gnoma Chart will use when rendering.  Merges active profile
  specific defaults in.  Active profile maps of default are defined by

    gnomaDefaults-<profile>
*/}}
{{- define "gnoma-renderer.gatherGnomaDefaults" }}
  {{- $ := . }}

  {{- $_ := set $.Values "gnomaDefaults" ($.Values.gnomaDefaults | default dict) }}

  {{- range $profile := $.Values.gnomaProfiles }}
    {{- $profileDefaultsMap := (get $.Values (printf "gnomaDefaults-%s" $profile)) }}
    {{- if $profileDefaultsMap }}
      {{- $_ set $.Values "gnomaProfiles"  (mergeOverwrite $.Values.gnomaDefaults) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-renderer.gatherGnomaTemplates
  ======================================

  PARAMETERS LIST:
    $ -> root of chart

  ======================================

  Collects all lists of the form "gnomaTemplates-*" from .Values and appends them to the gnomaTemplates list, and
  then confirms the gnomaTemplates list is not empty.  The chart will be failed if the gnomaTemplates list is empty.
*/}}
{{- define "gnoma-renderer.gatherGnomaTemplates" }}
  {{- $ := . }}

  {{- if $.Values.gnomaTemplates }}
    {{- if (not (kindIs "slice" $.Values.gnomaTemplates)) }}
        {{- fail "gnoma-renderer gnomaTemplates: must be defined" }}
    {{- end }}
  {{- end }}

  {{- range $key, $value := $.Values }}
    {{- if hasPrefix "gnomaTemplates-" $key }}
      {{- if $.Values.gnomaTemplates }}
        {{- $_ := set $.Values "gnomaTemplates" (concat $.Values.gnomaTemplates $value) }}
      {{- else }}
        {{- $_ := set $.Values "gnomaTemplates" $value }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $_ := required "Missing gnomaTemplates: list" $.Values.gnomaTemplates }}
{{- end }}


{{/*
  ======================================
  gnoma-renderer.filterTemplates
  ======================================

  Gnoma Chart templates may be condigured to only render or not render depending on the active profile(s).

  gnomaTemplates:
  - templateName: <template name>
    objName: <object name>
    mustHaveAnyProfile: <render if the active profile is list>
    mustNotHaveAnyProfile: <do NOT render if the active profile is list>
    mustHaveEveryProfile: <render only every profiles in list is active>
    mustHaveEveryProfile: <do NOT render only every profiles in list is active>

  Skipped templates will be listed when the Chart has completed rendering.
*/}}
{{- define "gnoma-renderer.filterTemplates" }}
  {{- $ := get . "$" }}
  {{- $templates := .gnomaTemplates }}

  {{- $_ := set $.Values "gnomaProfiles" ($.Values.gnomaProfiles | default list) }}

  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- $resultKey := uuidv4 }}
  {{- range $template := $templates }}
    {{- include "gnoma-renderer.processFilteringLists" (dict "$" $ "gnomaTemplate" $template "resultKey" $resultKey) }}

    {{- $hasMatchingProfile := not $template.mustHaveAnyProfile }}
    {{- range $profile := $template.mustHaveAnyProfile }}
      {{- $hasMatchingProfile = or $hasMatchingProfile (has $profile $.Values.gnomaProfiles) }}
    {{- end }}

    {{- $hasNoProhibitedProfiles := not $template.mustNotHaveAnyProfile }}
    {{- range $profile := $template.mustNotHaveAnyProfile }}
      {{- $hasNoProhibitedProfiles = or $hasNoProhibitedProfiles (has $profile $.Values.gnomaProfiles) }}
    {{- end }}
    {{- $hasNoProhibitedProfiles = or (not $template.mustNotHaveAnyProfile) (not $hasNoProhibitedProfiles) }}

    {{- $hasAllRequiredProfiles := true }}
    {{- range $profile := $template.mustHaveEveryProfile }}
      {{- $hasAllRequiredProfiles = and $hasAllRequiredProfiles (has $profile $.Values.gnomaProfiles) }}
    {{- end }}

    {{- $doesNotHaveAllProhibitedProfiles := true }}
    {{- range $profile := $template.mustNotHaveEveryProfile }}
      {{- $doesNotHaveAllProhibitedProfiles = and $doesNotHaveAllProhibitedProfiles (has $profile $.Values.gnomaProfiles) }}
    {{- end }}
    {{- $doesNotHaveAllProhibitedProfiles = or (not $template.doesNotHaveAllProhibitedProfiles) (not $doesNotHaveAllProhibitedProfiles) }}

    {{- if and $hasMatchingProfile $hasNoProhibitedProfiles $hasAllRequiredProfiles $doesNotHaveAllProhibitedProfiles  }}
      {{- $renderList = append $renderList $template }}
    {{- else }}
      {{- $objName := (empty $template.objNames | ternary (print "objName: " $template.objName) (print "objNames: " $template.objNames)) }}
      {{- $skippedList = append $skippedList (list $template.templateName $objName) }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "renderingTemplates" $renderList }}
  {{- $_ := set $.Values "skippedTemplates" $skippedList }}
{{- end }}

{{- define "gnoma-renderer.processFilteringLists" }}
  {{- $ := get . "$" }}
  {{- $template := .gnomaTemplate }}
  {{- $resultKey := .resultKey }}

  {{- $processValueArgs := (dict "$" $ "gnomaDefs" $.Values.gnomaDefs "resultKey" $resultKey) }}

  {{- $_ := set $template "mustHaveAnyProfile" ($template.mustHaveAnyProfile | default list) }}
  {{- $_ := set $processValueArgs "value" $template.mustHaveAnyProfile }}
  {{- $_ := set $processValueArgs "processedVarsList" list }}
  {{- include "gnoma-renderer.processValue" $processValueArgs }}
  {{- $_ := set $template "mustHaveAnyProfile" (get $.Values.__EC_RESULT_DICT $resultKey) }}
  {{- $_ := unset $.Values.__EC_RESULT_DICT $resultKey }}

  {{- $_ := set $template "mustNotHaveAnyProfile" ($template.mustNotHaveAnyProfile | default list) }}
  {{- $_ := set $processValueArgs "value" $template.mustNotHaveAnyProfile }}
  {{- $_ := set $processValueArgs "processedVarsList" list }}
  {{- include "gnoma-renderer.processValue" $processValueArgs }}
  {{- $_ := set $template "mustNotHaveAnyProfile" (get $.Values.__EC_RESULT_DICT $resultKey) }}
  {{- $_ := unset $.Values.__EC_RESULT_DICT $resultKey }}

  {{- $_ := set $template "mustHaveEveryProfile" ($template.mustHaveEveryProfile | default list) }}
  {{- $_ := set $processValueArgs "value" $template.mustHaveEveryProfile }}
  {{- $_ := set $processValueArgs "processedVarsList" list }}
  {{- include "gnoma-renderer.processValue" $processValueArgs }}
  {{- $_ := set $template "mustHaveEveryProfile" (get $.Values.__EC_RESULT_DICT $resultKey) }}
  {{- $_ := unset $.Values.__EC_RESULT_DICT $resultKey }}

  {{- $_ := set $template "mustNotHaveEveryProfile" ($template.mustNotHaveEveryProfile | default list) }}
  {{- $_ := set $processValueArgs "value" $template.mustNotHaveEveryProfile }}
  {{- $_ := set $processValueArgs "processedVarsList" list }}
  {{- include "gnoma-renderer.processValue" $processValueArgs }}
  {{- $_ := set $template "mustNotHaveEveryProfile" (get $.Values.__EC_RESULT_DICT $resultKey) }}
  {{- $_ := unset $.Values.__EC_RESULT_DICT $resultKey }}
{{- end }}