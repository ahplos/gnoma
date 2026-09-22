# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  gnoma-renderer.mergeGnomaDefs
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $gnomaDefsMap -> src map of Gnoma variable definitions
    $destGnomaDefs -> map in which results are merged into
    $baseObjName -> base objName, from the templates list of objNames if defined
    $objName -> objName of template

  ======================================

  Merges all gnomaDefs dictionaries based on profiles and object names to create a
  dictionary of variable definitions that will be used before finally rendering the Gnoma template.
  This template is called thre times for the overall chart.  The first time for some basic pre-processing
  of minimal template data such as profiles.  The next two times are for processing the templates for Gnoma
  variable references. First to merge all gnomaDefs defined directly under the .Values object, and then for
  each template specific variable definitions.

  Order of precedence in ascending order:

    1. gnomaDefsMap
       i. Parent map that contains all gnomaDef maps for merging.
          a. If merging variable definitions a the top level, this will be a copy of .Values.gnomaDefs
          b. If merging variable definitions for a template, this will be a copy of the fully merged, top level gnomaDefs map.
    2. gnomaDefs-<profile>
       i. Following Helm standard, in order of listed profiles first to last
    3. gnomaDefs-<baseObjName>
       i. baseObjName is the raw name from the objNames list before modification
    4. gnomaDefs-<objName>
       i. objName is the final, processed name of the resource being generated from the objNames list
    5. gnomaDefs-<baseObjName>-<profile>
       i. Same as gnomaDefs-<baseObjName>, but only for a specific profile, in first to last order of the profiles list
    6. gnomaDefs-<objName>-<profile>
       i. Same as gnomaDefs-<objName>, but only for a specific profile, in first to last order of the profiles list

    Merged results are contained in destGnomaDefs.
*/}}
{{- define "gnoma-renderer.mergeGnomaDefs" }}
  {{- $ := get . "$" }}
  {{- $gnomaDefsMap := .gnomaDefsMap }}
  {{- $destGnomaDefs := .destGnomaDefs }}
  {{- $baseObjName := .baseObjName }}
  {{- $objName := .objName }}

  {{- range $profile := $.Values.gnomaProfiles }}
    {{- if not (regexMatch $.Values.__EC_PROFILE_REGEX $profile) }}
      {{- fail (printf "profile \"%s\" does match regex naming requirements, \"%s\"" $profile $.Values.__EC_PROFILE_REGEX) }}
    {{- end }}
    {{- $profileDefs := get $gnomaDefsMap (printf "gnomaDefs-%s" $profile) }}
    {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $profileDefs "destDict" $destGnomaDefs) }}
  {{- end }}

  {{- if ne $baseObjName $objName }}
    {{- $baseObjNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s" $baseObjName) }}
    {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $baseObjNameDefs "destDict" $destGnomaDefs) }}
  {{- end }}

  {{- if $objName }}
    {{- $objNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s" $objName) }}
    {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $objNameDefs "destDict" $destGnomaDefs) }}
  {{- end }}

  {{- range $profile := $gnomaDefsMap.gnomaProfiles }}
    {{- if ne $baseObjName $objName }}
      {{- $baseObjNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s-%s" $profile $baseObjName) }}
      {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $baseObjNameDefs "destDict" $destGnomaDefs) }}

      {{- $baseObjNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s-%s" $baseObjName $profile) }}
      {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $baseObjNameDefs "destDict" $destGnomaDefs) }}
    {{- end }}

    {{- if $objName }}
      {{- $objNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s-%s" $profile $objName) }}
      {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $objNameDefs "destDict" $destGnomaDefs) }}

      {{- $objNameDefs := get $gnomaDefsMap (printf "gnomaDefs-%s-%s" $objName $profile) }}
      {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $objNameDefs "destDict" $destGnomaDefs) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  gnoma-renderer.deepCopyDict
  ======================================

  PARAMETERS LIST:
    $srcDict -> map to copy
    $destDict -> map to copy srcDict into

  ======================================

  Recursively copies all keys and values of a source dictionary into a destination dictionary; i.e. all maps
  contained in the source map and any of its values are copies of the original.  String and lists do not need
  to be copied, since they are immutable.

  NOTE: This template was created because of potential anamolies with Helm's deepcopy.  Will need to revisit in the future.
*/}}
{{- define "gnoma-renderer.deepCopyDict" }}
  {{- $srcDict := .srcDict }}
  {{- $destDict := .destDict }}

  {{- if $srcDict }}
    {{- range $key, $value := $srcDict }}
      {{- if (kindIs "map" $value) }}
        {{- $newValue := dict }}
        {{- include "gnoma-renderer.deepCopyDict" (dict "srcDict" $value "destDict" $newValue) }}
        {{- $value = $newValue }}
      {{- end }}
      {{- $_ := set $destDict $key $value }}
    {{- end }}
  {{- end }}
{{- end }}