#!/bin/sh
#
# Copyright 2020 IBM Corporation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http:#www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

{{ template "elk.settings.all.prepare" . -}}

set -uo pipefail

echo "`date` - 1. preparing to check .kibana index migration"
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
exit_code="-1"
while [ "$exit_code" != "0" ]
do
    echo "`date` - 2. looking for current .kibana index version"
    set -x
    resp_settings=$(curl -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt --fail $url/.kibana/_settings)
    exit_code=$?    
    set +x

    echo "exit_code=$exit_code, resp_settings=$resp_settings"

    if [ "$exit_code" == "0" ]; then
        echo "got 2xx http status code, checking response json..."

        echo "`date` - 3. identifying kibana version"
        created_by=$(echo $resp_settings| jq -r 'first(.[]).settings.index.version.created')
        if [[ -z "$created_by" ]]; then
            echo "no .kibana index found. use this as an indicator of a fresh install"
            created_by='6081099'
        fi

        echo "index version=$created_by"

        major_version="${created_by:0:1}"
        echo "major_version=$major_version"

        if [ "6" = "$major_version" ]; then
            echo "index version up-to-date"
            break
        else
            echo "upgrade still in progress from $created_by... sleep 10s"
            sleep 10
        fi
    else
        echo "got bad http response code $exit_code. retrying in 10s..."
        sleep 10
    fi     
done

echo "`date` - 4. Migration is DONE!"
