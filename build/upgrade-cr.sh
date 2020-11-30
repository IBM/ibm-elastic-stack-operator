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

# patch elasticstack cr to resolve upgrade issues
set -uo pipefail
exit_code=0

echo "`date` - 1. preparing cr info"
namespace=${1:-"ibm-common-services"}
cr_name=${2:-"logging"}

echo "`date` - 2. loading existing cr"
temp_file=$(mktemp)
set -x
kubectl get elasticstack/$cr_name -n $namespace -o yaml > $temp_file
set +x

if [ -s $temp_file ] 
then
    echo "unmodified cr:"
    cat $temp_file
else
    echo "cr doesn't exist. "
    echo "`date` - 2b. clean up"
    rm ${temp_file}

    echo "`date` - 2c. EXIT"
    echo "job exit code $exit_code"
    exit $exit_code
fi

operator_version=$(yq r $temp_file metadata.generation)
echo "operator_version=$operator_version"

echo "`date` - 3. preparing cr data for upgrade"
echo "`date` - 3a. removing fields added by operator"
set -x
yq d -i $temp_file status
yq d -i $temp_file metadata.creationTimestamp
yq d -i $temp_file metadata.finalizers
yq d -i $temp_file metadata.generation
yq d -i $temp_file metadata.resourceVersion
yq d -i $temp_file metadata.selfLink
yq d -i $temp_file metadata.uid
yq d -i $temp_file 'metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"'
yq d -i $temp_file metadata.managedFields
yq d -i $temp_file 'metadata.annotations."operator-sdk/primary-resource"'
yq d -i $temp_file 'metadata.annotations."operator-sdk/primary-resource-type"'
yq w -i $temp_file 'metadata.labels."operator.ibm.com/opreq-control"' true --style=double

set +x
echo "cr with fields preserved for recreation:"
cat $temp_file

echo "`date` - 4. deleting old cr"
set -x
kubectl delete elasticstack/$cr_name -n $namespace
set +x

echo "`date` - 5. deleting orphan resources"
set -x
kubectl get scc --no-headers=true | awk '/logging-elk/{print $1}'

kubectl delete --ignore-not-found=true scc logging-elk-elasticsearch
kubectl delete --ignore-not-found=true scc logging-elk-filebeat-ds
kubectl delete --ignore-not-found=true scc logging-elk-job
kubectl delete --ignore-not-found=true scc logging-elk-kibana
kubectl delete --ignore-not-found=true scc logging-elk-logstash

kubectl get scc --no-headers=true | awk '/logging-elk/{print $1}'

set +x

echo "`date` - 6. recreating cr"
set -x
kubectl apply -f ${temp_file} -n $namespace
set +x

echo "`date` - 7. clean up"
rm ${temp_file}

echo "`date` - 8. DONE"
echo "job exit code $exit_code"
exit $exit_code
