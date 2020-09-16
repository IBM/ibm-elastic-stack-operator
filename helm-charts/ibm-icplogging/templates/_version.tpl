{{/*
Licensed Materials - Property of IBM
  5737-E67
  @ Copyright IBM Corporation 2016, 2020. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*/}}

{{- /*
"sch.version" contains the version information and tillerVersion constraint
for this version of the Shared Configurable Helpers.
*/ -}}
{{- define "sch.version" -}}
version: "1.0.0"
tillerVersion: ">=2.9.1"
{{- end -}}
