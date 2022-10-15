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

if [[ "${LAUNCH_TYPE}" == "EC2" ]]; then
    LOADBALANCER_NAME="${APPLICATION_NAME}-loadbalancer"

    sed -e "s|APPLICATION_NAMESPACE|${APPLICATION_NAMESPACE}|g" \
        -e "s|APPLICATION_NAME|${APPLICATION_NAME}|g" \
        -e "s|LOADBALANCER_NAME|${LOADBALANCER_NAME}|g" \
        -i $CUR_DIR/templates/ibm-liberty-app-deploy-service.yaml

    echo "Deploying a load balancer for application ${APPLICATION_NAME}..."
    cat $CUR_DIR/templates/ibm-liberty-app-deploy-service.yaml
    kubectl apply -f $CUR_DIR/templates/ibm-liberty-app-deploy-service.yaml

    wait_for service "${LOADBALANCER_NAME}" ${APPLICATION_NAMESPACE}

    if [[ $? != 0 ]]; then
        echo "The load balancer for ${APPLICATION_NAME} is not available." >&2
        exit 1
    fi

    APP_ENDPOINT=$(kubectl get service ${LOADBALANCER_NAME} -n ${APPLICATION_NAMESPACE} -o=jsonpath='{.status.loadBalancer.ingress[*].hostname}')
    echo APPLICATION_ENDPOINT=${APP_ENDPOINT} >> $CUR_DIR/ibm-liberty-parameters.properties
    echo APPLICATION_ENDPOINT_URL=https://${APP_ENDPOINT} >> $CUR_DIR/ibm-liberty-parameters.properties
    separator
    echo "App deployed at https://${APP_ENDPOINT}"
    separator
fi
