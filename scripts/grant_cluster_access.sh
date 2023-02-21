#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-liberty-parameters.properties

if [[ ! -z "${EKS_ADMIN_USER_ARNS}" ]]; then
    echo "Granting access to the IAM entity (or entities) listed in ${CUR_DIR}/ibm-liberty-parameters.properties"
    echo "as the variable EKS_ADMIN_USER_ARNS: ${EKS_ADMIN_USER_ARNS}"

    # this loop uses bash string manipulation (https://tldp.org/LDP/abs/html/string-manipulation.html)
    # to replace all commas with spaces, so the for loop can iterate over each item
    for arn in ${EKS_ADMIN_USER_ARNS//,/ }
    do
        echo "Granting access to the IAM entity with ARN '${arn}'..."
        eksctl create iamidentitymapping --region "${AWS_DEFAULT_REGION}" --cluster "${EKS_CLUSTER_NAME}" --arn "${arn}" --group "system:masters"
    done
else
    echo "No IAM entity (or entities) listed in ${CUR_DIR}/ibm-liberty-parameters.properties as EKS_ADMIN_USER_ARNS."
    echo "Skipping procedure to grant admin access to additional IAM entities."
fi
