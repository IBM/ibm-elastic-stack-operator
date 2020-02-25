#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5737-E67
# @ Copyright IBM Corporation 2016, 2019. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# runTests script REQUIRED ONLY IF additional application verification is
# needed above and beyond helm tests.
#
# Parameters :
#   -c <chartReleaseName>, the name of the release used to install the helm chart
#
# Pre-req environment: authenticated to cluster, kubectl cli install / setup complete, & chart installed

# Exit when failures occur (including unset variables)
set -o errexit
set -o nounset
set -o pipefail

# Process parameters notify of any unexpected
while test $# -gt 0; do
  [[ $1 =~ ^-c|--chartrelease$ ]] && { chartRelease="$2"; shift 2; continue; };
  [[ $1 =~ ^-e|--endpoint$ ]] && { endpoint="$2"; shift 2; continue; };
  echo "Parameter not recognized: $1, ignored"
  shift
done
: "${chartRelease:="default"}"
: "${endpoint:="localhost"}"

# Parameters
# Below is the current set of parameters which are passed in to the app test script.
# The script can process or ignore the parameters
# The script can be coded to expect the parameter list below, but should not be coded such that additional parameters
# will cause the script to fail
#   -e <environment>, IP address of the environment
#   -r <release>, ie V.R.M.F-tag, the release notation associated with the environment, this will be V.R.M.F, plus an option -tag
#   -a <architecture>, the architecture of the environment
#   -u <userid>, the admin user id for the environment
#   -p <password>, the password for accessing the environment, base64 encoded, p=`echo p_enc | base64 -d` to decode the password when using


# Verify pre-req environment
command -v kubectl > /dev/null 2>&1 || { echo "kubectl pre-req is missing."; exit 1; }

# Setup and execute application test on installation
echo "Running application test on release $chartRelease"

sleep 20
curl -s http://${endpoint}:9200 | grep "You Know, for Search"
_testResult=$?

if [ $_testResult -eq 0 ]; then
  echo "SUCCESS - Connection successful"
else
  echo "FAIL"
fi
exit $_testResult
