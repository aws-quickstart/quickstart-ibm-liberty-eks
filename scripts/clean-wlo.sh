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
# Venu Beyagudem
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

#echo Cleaning up resources
kubectl delete deployment wlo-controller-manager --namespace ${WLO_NAMESPACE}
kubectl delete deployment websphereliberty-app-sample --namespace ${APPLICATION_NAMESPACE}
kubectl delete service websphereliberty-app-sample-loadbalancer --namespace ${APPLICATION_NAMESPACE}
