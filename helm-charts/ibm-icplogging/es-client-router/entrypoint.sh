#!/bin/sh
echo "Copying"
cp -f /opt/ibm/router/conf/nginx.conf /opt/ibm/router/nginx/conf/nginx.conf
cp -f /opt/ibm/router/rbac/rbac.lua /opt/ibm/router/nginx/conf/rbac.lua
cp -f /opt/ibm/router/qparser/qparser.lua /opt/ibm/router/nginx/conf/qparser.lua

{{- if eq (.Values.general.environment | lower) "openshift" }}
export OPENSHIFT_RESOLVER=$(cat /etc/resolv.conf |grep nameserver|awk '{split($0, a, " "); print a[2]}')
sed -i "s/{OPENSHIFT_RESOLVER}/${OPENSHIFT_RESOLVER}/g" /opt/ibm/router/nginx/conf/nginx.conf
{{- end }}

echo "Starting..."
nginx -g 'daemon off;'
