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

echo "Generating stack outputs..."

WLO_VERSION="$(kubectl get subscription ibm-websphere-liberty -n operators -o=jsonpath='{.status.installedCSV}' | grep --color=never -o '[0-9]\.[0-9]\.[0-9]')"
VPC_ID="$(eksctl get cluster --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER_NAME} -o json | jq -r '.[0].ResourcesVpcConfig.VpcId')"

cat <<EOF > $CUR_DIR/stack-outputs.properties
AppEndpoint=${APPLICATION_ENDPOINT_URL}
WLOVersion=${WLO_VERSION}
ClusterVpcId=${VPC_ID}
EOF

echo "Stack outputs:"
cat $CUR_DIR/stack-outputs.properties

echo "Writing outputs to SSM parameter store..."

aws ssm put-parameter \
    --type String \
    --name "/ibm/liberty-for-eks/${AWS_DEFAULT_REGION}/${WORKLOAD_STACK_NAME}/install-outputs" \
    --value "$(cat $CUR_DIR/stack-outputs.properties)"
    --overwrite

if [ $? != 0 ]; then
    echo "ERROR: Stack outputs were not written to SSM parameter store!"
    exit 1
fi

echo "Stack outputs written to SSM parameter store."
