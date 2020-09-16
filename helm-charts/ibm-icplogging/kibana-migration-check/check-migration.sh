#!/bin/sh
# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
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

    echo "`date` - 3. looking for current .kibana index version"
    temp_file=$(mktemp)
    set -x
    http_code=$(curl -o $temp_file -w '%{http_code}' -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt $url/.kibana/_settings)
    set +x

    resp=$(cat ${temp_file})
    rm ${temp_file}

    echo "http_code=$http_code, resp=$resp"

    case $http_code in
    "404")
        echo "no .kibana index found. use this as an indicator of a fresh install"
        echo "no need to wait for migration"
        break
        ;;
    "200")
        echo "got 200 http status code, checking response json..."
        echo "`date` - 4. identifying kibana version"
        created_by=$(echo $resp| jq -r 'first(.[]).settings.index.version.created')

        if [[ -z "$created_by" ]]; then
            echo "no .kibana index found. use this as an indicator of a fresh install"
            created_by='6081099'
        fi

        echo "$created_by=$created_by"

        major_version="${created_by:0:1}"
        echo "major_version=$major_version"

        if [ "6" = "$major_version" ]; then
            echo "index version up-to-date"
            break
        else
            echo "upgrade still in progress from $created_by... sleep 10s"
            sleep 10
        fi
        ;;
    *)
        echo "got bad http response code $http_code. retrying in 10s..."
        sleep 10
        ;;
    esac
done

echo "`date` - 5. Migration check is DONE!"
