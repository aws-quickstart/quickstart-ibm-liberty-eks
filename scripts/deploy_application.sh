#!/bin/bash
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
kubectl apply -f $appyaml 2>&1 | tee $CUR_DIR/appyaml.log

EXEC_STATE=`cat $CUR_DIR/appyaml.log | awk -F": " '{ print $2 }'`

if [[ $EXEC_STATE == "WebSphereLibertyApplication" ]]; then
    echo "The WebSphereLibertyApplication, ${APPLICATION_NAME}, failed to deploy with following exception." >&2
    cat $CUR_DIR/appyaml.log >&2
    DEPLOY="Failed"
    exit 1
else
    kubectl describe  webspherelibertyapplication.liberty.websphere.ibm.com/${APPLICATION_NAME}  --namespace ${APPLICATION_NAMESPACE} | tail -n 1 | grep "failed to call webhook" | tee $CUR_DIR/deploy.log
    DEPLOY_STATE=`cat $CUR_DIR/deploy.log | awk '{ print $2 }'`
    if [[ $DEPLOY_STATE == "ProcessingError" ]]; then
        echo "The WebSphereLibertyApplication, ${APPLICATION_NAME}, failed to deploy with following exception." >&2
        cat $CUR_DIR/deploy.log >&2
        DEPLOY="Failed"
        exit 1
    else

        wait_for deployment ${APPLICATION_NAME} ${APPLICATION_NAMESPACE}

        if [[ $? != 0 ]]; then
            echo "The WebSphereLibertyApplication ${APPLICATION_NAME} is not available." >&2
            DEPLOY="Failed"
            exit 1
        fi
    fi
fi
