#!/bin/sh
#
# Copyright 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

{{ template "elk.settings.all.prepare" . -}}

# if the kibana server returns a non-successful status,
# exit the job with this exit code. A retry will be triggered by k8s
set -uo pipefail
exit_code=0

# 1. prepare kibana api url
{{- if .Values.kibana.https }}
protocol=https
{{ else }}
protocol=http
{{- end }}

endpoint={{ .Values.kibana.name }}
port={{ .Values.kibana.internal }}
url="$protocol://$endpoint:$port"
index_pattern="logstash-*"
id="logstash-*"
time_field="@timestamp"

# if nginx is on
{{- if .Values.kibana.routerEnabled }}

# Appends "/kibana" or similar to path
url=$url{{ .Values.kibana.ingress.path }}

# 2. if nginx is on, get token from iam
# Use short name (without .svc.$CLUSTER_DOMAIN) to avoid ingress issues.
iam_url="https://iam-token-service.{{ .Release.Namespace }}:10443/oidc/token"
set -x
token=$(curl -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json" \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IAM_API_KEY&response_type=cloud_iam" \
    "$iam_url" \
    | jq '.access_token' | tr -d '"')

exit_code=$?
set +x
echo $'\n'
date
echo "curl returned code $exit_code"
{{- end }}

# 3. make kibana call to set index pattern
# more api info at: https://github.com/elastic/kibana/issues/3709
if [ "${exit_code}" = "0" ] || [ "${exit_code}" = "22" ]
then
    echo creating index pattern
    set -x
    curl -f -k -XPOST -H "Content-Type:application/json" \
    {{- if .Values.kibana.routerEnabled }}
    -H "Authorization: Bearer $token" \
    -H "router-api-key: $ROUTER_API_KEY" \
    {{- end }}
    -H "kbn-xsrf:anything" $url/api/saved_objects/index-pattern/$id \
    -d "{ \"attributes\": {\"title\":\"$index_pattern\",\"timeFieldName\":\"$time_field\"}}"
    exit_code=$?
    set +x
    echo $'\n'
    date
    echo "curl returned code $exit_code"
else
    echo "index pattern creation failed"
fi

# 3. make kibana call to set default index
# curl exits with code 22 for 409 error
# kibana returns 409 when the index pattern already exists
if [ "${exit_code}" = "0" ] || [ "${exit_code}" = "22" ]
then
    echo setting default index
    set -x
    curl -f -k -XPOST -H "Content-Type: application/json" \
    {{- if .Values.kibana.routerEnabled }}
    -H "Authorization: Bearer $token" \
    -H "router-api-key: $ROUTER_API_KEY" \
    {{- end }}
    -H "kbn-xsrf: anything" \
    "$url/api/kibana/settings/defaultIndex" \
    -d "{\"value\":\"$id\"}"
    exit_code=$?
    set +x
    echo $'\n'
    date
    echo "curl returned code $exit_code"
else
    echo "default index not set as index pattern creation failed"
fi

echo "job exit code $exit_code"
exit $exit_code
