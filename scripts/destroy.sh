#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-liberty-parameters.properties

export AWS_DEFAULT_REGION

if eksctl get cluster "${EKS_CLUSTER_NAME}"; then
    echo "Deleting cluster ${EKS_CLUSTER_NAME}..."
    eksctl delete cluster --wait "${EKS_CLUSTER_NAME}"
else
    echo "Cluster ${EKS_CLUSTER_NAME} does not exist."
fi
