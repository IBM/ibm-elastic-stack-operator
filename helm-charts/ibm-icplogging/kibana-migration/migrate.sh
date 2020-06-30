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

# [1] Check and wait until elasticsearch is up and sends back good json response
json_exit="1"
counter=0
max_wait=20
while [ "$json_exit" != "0" -a "$json_exit" != "" ]
do
    # wait a bit for elasticsearch
    sleep 10

    {{- if .Values.elasticsearch.security.authc.enabled }}
    status=$(curl -s -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt -o /tmp/deprecations.json -w '%{http_code}' $url/_xpack/migration/deprecations)
    {{ else }}
    status=$(curl -s -o /tmp/deprecations.json -w '%{http_code}' $url/_xpack/migration/deprecations)
    {{- end }}

    if [ "$status" == "200" ]; then
        echo "got 200 http status code, checking json."
        # check if we got good json back
        json_exit=$(cat /tmp/deprecations.json | jq empty)
        echo "josn exit code $json_exit"
        if [ "$json_exit" != "0" -a "$json_exit" != "" ]; then
            echo "`date` possible bad json $json_exit. retry ..."
        fi
    fi

    if [ $counter -eq $max_wait ]; then
        break
    fi
    counter=`expr $counter + 1`
done

if [ $counter -eq $max_wait -a "$json_exit" != "200" ]; then
    echo "`date` Did not get got json response in specified time, exiting..."
    exit $json_exit
fi

kibanaIndex=$(cat /tmp/deprecations.json | jq '.index_settings[".kibana"][0].message' | tr -d '"')
echo "`date` status of .kibana index: ${kibanaIndex}"

# [2] Check if the .kibana index should be migrated, if yes, then, issue rest api call to migrate
# Reference: https://www.elastic.co/guide/en/kibana/current/migrating-6.0-index.html
if [ "${kibanaIndex}" == "Index created before 6.0" ]; then
    # prepare the json
    json1='{
        "index.blocks.write": true
    }'
    json2='{
        "settings" : {
            "number_of_shards" : 1,
            "index.mapper.dynamic": false
        },
        "mappings" : {
            "doc": {
            "properties": {
                "type": {
                "type": "keyword"
                },
                "updated_at": {
                "type": "date"
                },
                "config": {
                "properties": {
                    "buildNum": {
                    "type": "keyword"
                    }
                }
                },
                "index-pattern": {
                "properties": {
                    "fieldFormatMap": {
                    "type": "text"
                    },
                    "fields": {
                    "type": "text"
                    },
                    "intervalName": {
                    "type": "keyword"
                    },
                    "notExpandable": {
                    "type": "boolean"
                    },
                    "sourceFilters": {
                    "type": "text"
                    },
                    "timeFieldName": {
                    "type": "keyword"
                    },
                    "title": {
                    "type": "text"
                    }
                }
                },
                "visualization": {
                "properties": {
                    "description": {
                    "type": "text"
                    },
                    "kibanaSavedObjectMeta": {
                    "properties": {
                        "searchSourceJSON": {
                        "type": "text"
                        }
                    }
                    },
                    "savedSearchId": {
                    "type": "keyword"
                    },
                    "title": {
                    "type": "text"
                    },
                    "uiStateJSON": {
                    "type": "text"
                    },
                    "version": {
                    "type": "integer"
                    },
                    "visState": {
                    "type": "text"
                    }
                }
                },
                "search": {
                "properties": {
                    "columns": {
                    "type": "keyword"
                    },
                    "description": {
                    "type": "text"
                    },
                    "hits": {
                    "type": "integer"
                    },
                    "kibanaSavedObjectMeta": {
                    "properties": {
                        "searchSourceJSON": {
                        "type": "text"
                        }
                    }
                    },
                    "sort": {
                    "type": "keyword"
                    },
                    "title": {
                    "type": "text"
                    },
                    "version": {
                    "type": "integer"
                    }
                }
                },
                "dashboard": {
                "properties": {
                    "description": {
                    "type": "text"
                    },
                    "hits": {
                    "type": "integer"
                    },
                    "kibanaSavedObjectMeta": {
                    "properties": {
                        "searchSourceJSON": {
                        "type": "text"
                        }
                    }
                    },
                    "optionsJSON": {
                    "type": "text"
                    },
                    "panelsJSON": {
                    "type": "text"
                    },
                    "refreshInterval": {
                    "properties": {
                        "display": {
                        "type": "keyword"
                        },
                        "pause": {
                        "type": "boolean"
                        },
                        "section": {
                        "type": "integer"
                        },
                        "value": {
                        "type": "integer"
                        }
                    }
                    },
                    "timeFrom": {
                    "type": "keyword"
                    },
                    "timeRestore": {
                    "type": "boolean"
                    },
                    "timeTo": {
                    "type": "keyword"
                    },
                    "title": {
                    "type": "text"
                    },
                    "uiStateJSON": {
                    "type": "text"
                    },
                    "version": {
                    "type": "integer"
                    }
                }
                },
                "url": {
                "properties": {
                    "accessCount": {
                    "type": "long"
                    },
                    "accessDate": {
                    "type": "date"
                    },
                    "createDate": {
                    "type": "date"
                    },
                    "url": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                        "type": "keyword",
                        "ignore_above": 2048
                        }
                    }
                    }
                }
                },
                "server": {
                "properties": {
                    "uuid": {
                    "type": "keyword"
                    }
                }
                },
                "timelion-sheet": {
                "properties": {
                    "description": {
                    "type": "text"
                    },
                    "hits": {
                    "type": "integer"
                    },
                    "kibanaSavedObjectMeta": {
                    "properties": {
                        "searchSourceJSON": {
                        "type": "text"
                        }
                    }
                    },
                    "timelion_chart_height": {
                    "type": "integer"
                    },
                    "timelion_columns": {
                    "type": "integer"
                    },
                    "timelion_interval": {
                    "type": "keyword"
                    },
                    "timelion_other_interval": {
                    "type": "keyword"
                    },
                    "timelion_rows": {
                    "type": "integer"
                    },
                    "timelion_sheet": {
                    "type": "text"
                    },
                    "title": {
                    "type": "text"
                    },
                    "version": {
                    "type": "integer"
                    }
                }
                },
                "graph-workspace": {
                "properties": {
                    "description": {
                    "type": "text"
                    },
                    "kibanaSavedObjectMeta": {
                    "properties": {
                        "searchSourceJSON": {
                        "type": "text"
                        }
                    }
                    },
                    "numLinks": {
                    "type": "integer"
                    },
                    "numVertices": {
                    "type": "integer"
                    },
                    "title": {
                    "type": "text"
                    },
                    "version": {
                    "type": "integer"
                    },
                    "wsState": {
                    "type": "text"
                    }
                }
                }
            }
            }
        }
    }'
    json3='{
        "source": {
            "index": ".kibana"
        },
        "dest": {
            "index": ".kibana-6"
        },
        "script": {
            "inline": "ctx._source = [ ctx._type : ctx._source ]; ctx._source.type = ctx._type; ctx._id = ctx._type + \":\" + ctx._id; ctx._type = \"doc\"; ",
            "lang": "painless"
        }
    }'
    json4='{
        "actions" : [
            { "add":  { "index": ".kibana-6", "alias": ".kibana" } },
            { "remove_index": { "index": ".kibana" } }
        ]
    }'

    echo "`date` Start migrating .kibana index ..."

    {{- if .Values.elasticsearch.security.authc.enabled }}
    curl -s -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt  -X PUT "$url/.kibana/_settings" -H 'Content-Type: application/json' -d"${json1}"
    curl -s -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt -X PUT "$url/.kibana-6" -H 'Content-Type: application/json' -d"${json2}"
    curl -s -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt -X POST "$url/_reindex" -H 'Content-Type: application/json' -d"${json3}"
    curl -s -E $CERT_DIR/curator.crt --key $CERT_DIR/curator.key --cacert $CERT_DIR/ca.crt  -X POST "$url/_aliases" -H 'Content-Type: application/json' -d"${json4}"
    {{ else }}
    curl -s -X PUT "$url/.kibana/_settings" -H 'Content-Type: application/json' -d"${json1}"
    curl -s -X PUT "$url/.kibana-6" -H 'Content-Type: application/json' -d"${json2}"
    curl -s -X POST "$url/_reindex" -H 'Content-Type: application/json' -d"${json3}"
    curl -s -X POST "$url/_aliases" -H 'Content-Type: application/json' -d"${json4}"
    {{- end }}
fi

echo "`date` Migration is DONE!"
exit 0
