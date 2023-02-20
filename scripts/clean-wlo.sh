#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

#echo Cleaning up resources
kubectl delete deployment wlo-controller-manager --namespace ${WLO_NAMESPACE}
kubectl delete deployment websphereliberty-app-sample --namespace ${APPLICATION_NAMESPACE}
kubectl delete service websphereliberty-app-sample-loadbalancer --namespace ${APPLICATION_NAMESPACE}
