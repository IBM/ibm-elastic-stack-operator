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

#!/bin/sh
set -uo pipefail

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
while :
do
    # Check and wait until elasticsearch is up and sends back good json response
    json_exit="1"
    while [ "$json_exit" != "0" -a "$json_exit" != "" ]
    do
        set -x
        {{- if .Values.elasticsearch.security.authc.enabled }}  
        status=$(curl -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt -o /tmp/deprecations.json -w '%{http_code}' $url/_xpack/migration/deprecations)
        {{ else }}
        status=$(curl -o /tmp/deprecations.json -w '%{http_code}' $url/_xpack/migration/deprecations)
        {{- end }}
        set +x

        if [ "$status" == "200" ]; then
            echo "got 200 http status code, checking json."
            # check if we got good json back
            json_exit=$(cat /tmp/deprecations.json | jq empty)
            echo "josn exit code $json_exit"
            if [ "$json_exit" != "0" -a "$json_exit" != "" ]; then
                echo "`date` possible bad json $json_exit. retry ..."
                sleep 10
            fi
        else
            echo "got bad http response code $status. retry ..."
            sleep 10
        fi
    done

    kibanaIndex=$(cat /tmp/deprecations.json | jq '.index_settings[".kibana"][0].message' | tr -d '"')
    echo "`date` status of .kibana index: ${kibanaIndex}"
    if [ "${kibanaIndex}" == "Index created before 6.0" ]; then
        echo "`date` still migrating... sleep "
        sleep 10
    else
        break
    fi
done

echo "`date` Migration is DONE!"
exit 0
