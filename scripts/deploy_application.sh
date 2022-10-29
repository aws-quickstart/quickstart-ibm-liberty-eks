#!/bin/bash
# *********************************************************************
# * IBM Confidential
# * OCO Source Materials
# *
# * Copyright IBM Corp. 2022
# *
# * The source code for this program is not published or otherwise
# * divested of its trade secrets, irrespective of what has been
# * deposited with the U.S. Copyright Office.
# *********************************************************************
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-liberty-parameters.properties
source $CUR_DIR/utilities.sh


appyaml="$CUR_DIR/templates/ibm-liberty-app-deploy.yaml"
echo "APPLICATION_DEPLOY=$APPLICATION_DEPLOY, deploying $appyaml."

# Add parameter values to the app CRD
sed -e "s|APPLICATION_NAMESPACE|${APPLICATION_NAMESPACE}|g" \
    -e "s|APPLICATION_NAME|${APPLICATION_NAME}|g" \
    -e "s|APPLICATION_IMAGE_URL|${APPLICATION_IMAGE_URL}|g" \
    -e "s|APPLICATION_REPLICAS|${APPLICATION_REPLICAS}|g" \
    -e "s|LICENSE_EDITION|${LICENSE_EDITION}|g" \
    -e "s|LICENSE_METRIC|${LICENSE_METRIC}|g" \
    -e "s|LICENSE_ENTITLEMENT|${LICENSE_ENTITLEMENT}|g" \
    -i $appyaml

echo "Deploying application ${APPLICATION_NAME}..."
cat $appyaml
kubectl apply -f $appyaml

wait_for deployment ${APPLICATION_NAME} ${APPLICATION_NAMESPACE}

if [[ $? != 0 ]]; then
    echo "The WebSphereLibertyApplication ${APPLICATION_NAME} is not available." >&2
    DEPLOY="Failed"
    exit 1
fi
