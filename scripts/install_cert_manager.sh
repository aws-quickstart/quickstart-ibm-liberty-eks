#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-liberty-parameters.properties
source $CUR_DIR/utilities.sh

echo "Installing cert-manager..."
kubectl create -f https://operatorhub.io/install/cert-manager.yaml

wait_for deployment cert-manager-webhook operators

if [[ $? != 0 ]]; then
    echo "cert-manager failed to install."
    exit 1
fi

# Fix cert-manager-webhook's default port, which doesn't work on Fargate
if [[ "${LAUNCH_TYPE}" == "Fargate" ]]; then
    separator
    echo "The cert-manager-webhook default port has a conflict on Fargate clusters."
    echo "Changing the default port from 10250 to 10260 to fix this issue."
    kubectl get deployment -n cert-manager cert-manager-webhook -o yaml \
        | sed '20,$ s/10250/10260/g' \
        | kubectl apply -f -
fi
