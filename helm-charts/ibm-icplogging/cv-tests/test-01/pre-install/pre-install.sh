#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2019. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Pre-install script REQUIRED ONLY IF additional setup is required prior to
# helm install for this test path.
#
# For example, if PersistantVolumes (PVs) are required for chart installation
# they will need to be created prior to helm install.
#
# Parameters :
#   -c <chartReleaseName>, the name of the release used to install the helm chart
#
# Pre-req environment: authenticated to cluster & kubectl cli install / setup complete

# Exit when failures occur (including unset variables)
set -o errexit
set -o nounset
set -o pipefail

# Verify pre-req environment
command -v kubectl > /dev/null 2>&1 || { echo "kubectl pre-req is missing."; exit 1; }

# Create pre-requisite components
# For example, create pre-requisite PV/PVCs using yaml definition in current directory
[[ `dirname $0 | cut -c1` = '/' ]] && preinstallDir=`dirname $0`/ || preinstallDir=`pwd`/`dirname $0`/

# Process parameters notify of any unexpected
while test $# -gt 0; do
	[[ $1 =~ ^-c|--chartrelease$ ]] && { chartRelease="$2"; shift 2; continue; };
    echo "Parameter not recognized: $1, ignored"
    shift
done
: "${chartRelease:="default"}"

sed 's/{{ release }}/'$chartRelease'/g' $preinstallDir/values-template.yaml > $preinstallDir/../values.yaml

kubectl delete --ignore-not-found=true secret logregcred
kubectl create secret docker-registry logregcred --docker-server=hyc-cloud-private-integration-docker-local.artifactory.swg-devops.com/ibmcom --docker-username=sbates@us.ibm.com --docker-password=AKCp5btAwG44ubUxh9d2xQ99cKcemx2rbapLS1dudfBRcB9VuJEXgJSWmL8Pfrg8vr3WLLEeL --docker-email=sbates@us.ibm.com
