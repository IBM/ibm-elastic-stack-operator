{{/*
  Copyright 2020 IBM Corporation

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http:#www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified filebeat server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "filebeat.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.filebeat.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified client node name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "client.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.elasticsearch.client.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified test pod name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "test.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "test" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified router resource name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "router.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "router" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified elasticsearch name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.elasticsearch.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified data node name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "data.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.elasticsearch.data.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified master node name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "master.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.elasticsearch.master.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified kibana name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kibana.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.kibana.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified logstash name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "logstash.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.logstash.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified job name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "job.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "job" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
To avoid split-brain we need to set the minimum number of master pods to (elasticsearch.master.replicas / 2) + 1.
Expected input -> output:
  - 0 -> 0
  - 1 -> 1
  - 2 -> 2
  - 3 -> 2
  - 9 -> 5, etc
If the calculated value is higher than the # of replicas, use the replica value.
*/}}
{{- define "elasticsearch.master.minimumNodes" -}}
{{- $replicas := int (default 1 .Values.elasticsearch.data.replicas) -}}
{{- $min := add1 (div $replicas 2) -}}
{{- if gt $min $replicas -}}
  {{- printf "%d" $replicas -}}
{{- else -}}
  {{- printf "%d" $min -}}
{{- end -}}
{{- end -}}

{{/*
Allow for private repository support.
*/}}
{{- define "image.pullSecret" -}}
{{- if .Values.image.pullSecret.enabled -}}
imagePullSecrets:
  - name: {{ .Values.image.pullSecret.name }}
{{- end }}
{{- end }}

{{- define "image.calculateImage" -}}
    {{- $params := . -}}
    {{- $repo := (index $params 0) -}}
    {{- $tag := (index $params 1) -}}
    {{- $digest := (index $params 2) -}}
    {{- $repo -}}
    {{- if $digest -}}
      @{{- $digest -}}
    {{- else -}}
      :{{- $tag -}}
    {{- end -}}
{{- end -}}

{{- define "metadata.calculateLabels" -}}
    {{- $params := . -}}
    {{- $scope := (index $params 0) -}}
    {{- $app := (index $params 1) -}}
    {{- $component := (index $params 2) -}}
    {{- $role := (index $params 3) -}}
app: "{{ $app }}"
component: "{{ $component }}"
role: "{{ $role }}"
release: "{{ $scope.Release.Name }}"
chart: "{{ $scope.Chart.Name }}-{{ $scope.Chart.Version }}"
heritage: "{{ $scope.Release.Service }}"
  {{- if eq ($scope.Values.general.environment | lower) "openshift" }}
app.kubernetes.io/instance: "common-logging"
  {{- end }}
{{- end -}}

{{- define "metadata.calculateAnnotations" -}}
    {{- $params := . -}}
    {{- $scope := (index $params 0) -}}
scheduler.alpha.kubernetes.io/critical-pod: ""
  {{- if eq ($scope.Values.general.environment | lower) "openshift" }}
productName: "IBM Cloud Platform Common Services"
productID: "068a62892a1e4db39641342e592daa25"
productVersion: "3.4.0"
productMetric: "FREE"
clusterhealth.ibm.com/dependencies: auth-idp, auth-pap, auth-pdp
  {{- else }}
productName: Elasticsearch
productVersion: 6.8.10
productID: none
  {{- end }}
{{- end -}}

{{/*
The name of the cluster domain for ICP's OIDC.
*/}}
{{- define "clusterDomain" -}}
{{- default "cluster.local" .Values.general.clusterDomain -}}
{{- end -}}

{{/*
The name of the cluster for ICP's OIDC.
*/}}
{{- define "clusterName" -}}
{{- default "mycluster" .Values.general.clusterName -}}
{{- end -}}

{{/*
Generator for the API version of a Kubernetes resource. Tests capabilities to see if "apps/v1" is available,
uses "extensions/v1beta1" if not.
*/}}
{{- define "apiVersionTryV1" -}}
{{ if .Capabilities.APIVersions.Has "apps/v1" -}}
apiVersion: apps/v1
{{- else -}}
apiVersion: apps/v1beta2
{{- end }}
{{- end -}}

{{/*
Set .Values.elasticsearch.security.* parameter default values
and translate legacy values (pre 3.2.0)
*/}}
{{- define "elasticsearch.settings.security.prepare" -}}
  {{- if not .Values.elasticsearch.security }}
    {{- set .Values.elasticsearch "security" dict }}
    {{- set .Values.elasticsearch.security "authc" dict }}
    {{- set .Values.elasticsearch.security "authz" dict }}
    {{- if .Values.security.enabled }}
      {{- set .Values.elasticsearch.security.authc "enabled" true }}
      {{- set .Values.elasticsearch.security.authc "provider" .Values.security.provider }}
      {{- set .Values.elasticsearch.security.authz "enabled" false }}
      {{- set .Values.elasticsearch.security.authz "provider" "" }}
    {{- else }}
      {{- set .Values.elasticsearch.security.authc "enabled" false }}
      {{- set .Values.elasticsearch.security.authc "provider" "" }}
      {{- set .Values.elasticsearch.security.authz "enabled" false }}
      {{- set .Values.elasticsearch.security.authz "provider" "" }}
      {{- set .Values.kibana "httpOffByLegacy" true }}
    {{- end }}
  {{- end }}
  {{- if not .Values.elasticsearch.security.authc.enabled }}
    {{- set .Values.elasticsearch.security.authz "enabled" false }}
    {{- set .Values.elasticsearch.security.authz "provider" "" }}
  {{- end }}
{{- end -}}

{{/*
Set .Values.kibana.security.* parameter for pre 3.2.0 users
*/}}
{{- define "kibana.settings.security.prepare" -}}
  {{- if not .Values.kibana.security }}
    {{- set .Values.kibana "security" dict }}
    {{- set .Values.kibana.security "authc" dict }}
    {{- set .Values.kibana.security "authz" dict }}
    {{- set .Values.kibana.security.authc "enabled" false }}
    {{- set .Values.kibana.security.authc "provider" "" }}
    {{- set .Values.kibana.security.authz "enabled" false }}
    {{- set .Values.kibana.security.authz "provider" "" }}
  {{- end }}
{{- end }}

{{/*
Set .Values.kibana.access.* parameter for pre 3.2.0 users
*/}}
{{- define "kibana.settings.access.prepare" -}}
  {{- if not .Values.kibana.access }}
    {{- if eq .Values.general.mode "managed" }}
      {{- set .Values.kibana "access" "ingress" }}
      {{- set .Values.kibana "ingress" dict }}
      {{- set .Values.kibana.ingress "path" "/kibana" }}
    {{- else }}
      {{- set .Values.kibana "access" "loadBalancer" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Set .Values.kibana.ingress.* parameter
*/}}
{{- define "kibana.settings.ingress.prepare" -}}
  {{- if ne "ingress" .Values.kibana.access }}
    {{- set .Values.kibana.ingress "path" "" }}
  {{- end -}}
{{- end }}

{{/*
calculate if kibana router is needed. router is only needed for icp authc/z
*/}}
{{- define "kibana.settings.router.prepare" -}}
  {{- set .Values.kibana "routerEnabled" false }}
  {{- if .Values.kibana.security.authc.enabled }}
    {{- if eq "icp" .Values.kibana.security.authc.provider }}
      {{- set .Values.kibana "routerEnabled" true }}
    {{- end }}
  {{- end }}
  {{- if .Values.kibana.security.authz.enabled }}
    {{- if eq "icp" .Values.kibana.security.authz.provider }}
      {{- set .Values.kibana "routerEnabled" true }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
determine if kibana uses https. http is only used for legacy users when security.enabled=false
*/}}
{{- define "kibana.settings.https.prepare" -}}
  {{- if .Values.kibana.httpOffByLegacy }}
    {{- set .Values.kibana "https" false }}
  {{- else }}
    {{- set .Values.kibana "https" true }}
  {{- end }}
{{- end }}

{{/*
calculate if es client router is needed. router is only needed for icp authz
*/}}
{{- define "elasticsearch.settings.router.prepare" -}}
  {{- set .Values.elasticsearch "routerEnabled" false }}
  {{- if .Values.elasticsearch.security.authz.enabled }}
    {{- if eq "icp" .Values.elasticsearch.security.authz.provider }}
      {{- set .Values.elasticsearch "routerEnabled" true }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
calculate if pki init job is needed
*/}}
{{- define "security.settings.pki.prepare" -}}
  {{- set .Values.general "pkiInitEnabled" false }}
  {{- if .Values.elasticsearch.security.authc.enabled }}
    {{- set .Values.general "pkiInitEnabled" true }}
  {{- end }}
  {{- if .Values.kibana.https }}
    {{- set .Values.general "pkiInitEnabled" true }}
  {{- end }}
{{- end }}

{{/*
prepare all the settings
*/}}
{{- define "elk.settings.all.prepare" -}}
  {{ include "elasticsearch.settings.security.prepare" . | substr 0 0 -}}
  {{ include "elasticsearch.settings.router.prepare" . | substr 0 0 -}}
  {{ include "kibana.settings.access.prepare" . | substr 0 0 -}}
  {{ include "kibana.settings.security.prepare" . | substr 0 0 -}}
  {{ include "kibana.settings.router.prepare" . | substr 0 0 -}}
  {{ include "kibana.settings.https.prepare" . | substr 0 0 -}}
  {{ include "kibana.settings.ingress.prepare" . | substr 0 0 -}}
  {{ include "security.settings.pki.prepare" . | substr 0 0 -}}
{{- end }}

{{/*
Remove sensitive info from values
*/}}
{{- define "elk.settings.all.redact" -}}
  {{- $copy := merge dict .Values }}

  {{- $_ := set $copy "security" dict }}

  {{- $_ := set $copy.security "app" dict }}
  {{- $_ := set $copy.security "ca" dict }}

  {{- $_ := set $copy.security.app "keystore" dict }}
  {{- $_ := set $copy.security.ca "keystore" dict }}
  {{- $_ := set $copy.security.ca "truststore" dict }}

  {{- if .Values.security.app }}
    {{- if .Values.security.app.keystore }}
      {{- $_ := merge $copy.security.app.keystore .Values.security.app.keystore }}
      {{- $_ := set $copy.security.app.keystore "password" "redacted" }}
    {{- end }}
  {{- end }}
  {{- if .Values.security.ca }}
    {{- if .Values.security.ca.keystore }}
      {{- $_ := merge $copy.security.ca.keystore .Values.security.ca.keystore }}
      {{- $_ := set $copy.security.ca.keystore "password" "redacted" }}
    {{- end }}
    {{- if .Values.security.ca.truststore }}
      {{- $_ := merge $copy.security.ca.truststore .Values.security.ca.truststore }}
      {{- $_ := set $copy.security.ca.truststore "password" "redacted" }}
    {{- end }}
  {{- end }}

{{- $copy | toYaml }}
{{- end }}
