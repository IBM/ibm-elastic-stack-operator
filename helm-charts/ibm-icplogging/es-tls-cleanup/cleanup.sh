#!/bin/sh
#
# Copyright 2020 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
{{ template "elk.settings.all.prepare" . -}}
set -uo pipefail

echo "`date` - 1. preparing to remove obsolete tls index"
# Prepare es client api url
{{- if .Values.elasticsearch.security.authc.enabled }}
# Use https protcol if security enabled
protocol=https
export CERT_DIR=/usr/share/elasticsearch/config/tls
{{ else }}
# Use http protcol if security disabled
protocol=http
{{- end }}

endpoint={{ .Values.elasticsearch.name }}
port={{ .Values.elasticsearch.client.restPort }}
url="$protocol://$endpoint:$port"

# Check if the .kibana index migration is done
# Check and wait until elasticsearch is up and sends back good json response
while true
do
    echo "`date` - 2. checking if Elasticsearch is up"
    temp_file=$(mktemp)
    set -x
    http_code=$(curl -o $temp_file -w '%{http_code}' -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt $url)
    set +x

    resp=$(cat ${temp_file})
    rm ${temp_file}

    echo "http_code=$http_code, resp=$resp"

    if [ "$http_code" != "200" ]; then
        echo "Elasticsearch is not up yet... sleep 10s"
        sleep 10
        continue
    fi

    echo "`date` - 3. removing obsolete tls index"
    temp_file=$(mktemp)
    set -x
    http_code=$(curl -o $temp_file -w '%{http_code}' -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt -XDELETE $url/searchguard)
    set +x

    resp=$(cat ${temp_file})
    rm ${temp_file}

    echo "http_code=$http_code, resp=$resp"

    case $http_code in
    "404")
        echo "obsolete tls index not present. no need to delete"
        break
        ;;
    "200")
        echo "got 200 http status code. delete success!"
        ;;
    *)
        echo "got bad http response code $http_code. retrying in 10s..."
        sleep 10
        ;;
    esac
done

echo "`date` - 4. Cleanup is DONE!"
