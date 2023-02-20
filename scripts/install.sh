#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
source $CUR_DIR/ibm-liberty-parameters.properties
source $CUR_DIR/utilities.sh

sudo yum install -y -q jq


create_fargate_profile() {
    namespace=$1

    if [[ -z "${namespace}" || "${namespace}" == "''" ]]; then
        # If the namespace is blank, just skip it.
        return 0
    fi

    if eksctl get fargateprofiles --cluster "${EKS_CLUSTER_NAME}" | awk '{print $2}' | grep "${namespace}" >/dev/null; then
        echo "A Fargate profile for the ${namespace} namespace already exists."
    else
        echo "Creating a Fargate profile to run pods in the ${namespace} namespace..."
        eksctl create fargateprofile --cluster "${EKS_CLUSTER_NAME}" --name "${namespace}" --namespace "${namespace}"
        # Wait a little longer to make sure the profile is ready so pods won't get stuck in pending state.
        sleep 15s
    fi
}

create_namespace() {
    namespace=$1

    if ! kubectl get namespace "${namespace}" >/dev/null; then
        echo "Creating the namespace '${namespace}'..."
        kubectl create namespace "${namespace}"
    else
        echo "The namespace ${namespace} already exists."
    fi
}

# Setup CloudWatch Logs
separator
$CUR_DIR/setup-cloudwatch-logs.sh
separator

# Update aws cli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# On the EC2 instance, out of the box, aws command is installed at /usr/bin/aws and is older version
#      aws --version => aws-cli/1.18.147 Python/2.7.18 Linux/4.14.231-173.361.amzn2.x86_64 botocore/1.18.6
# By default, (aws cli install) files are all installed to /usr/local/aws-cli, and a symbolic link is created in /usr/local/bin.
if ! aws --version | grep --color=never 'aws-cli/2'; then
    echo "Version 1 of the AWS CLI is installed. Updating to version 2."
    sudo rm -rf `which aws`
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscli_new.zip"
    unzip -u -q awscli_new.zip
    sudo ./aws/install
    export PATH=/usr/local/bin:${PATH}
    echo "Updated aws cli version:" `aws --version`
fi

# Update the .kube/config file to access the cluster with kubectl
echo "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}"
aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}

separator

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "kubectl version: " `kubectl version`

separator

# Install OLM: https://olm.operatorframework.io/docs/getting-started/
OLM_LATEST_VERSION="$(curl -s https://api.github.com/repos/operator-framework/operator-lifecycle-manager/releases/latest | jq -r '.tag_name')"
echo "Installing OLM version ${OLM_LATEST_VERSION}..."
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_LATEST_VERSION}/install.sh -o install.sh
chmod +x install.sh
./install.sh ${OLM_LATEST_VERSION}

separator

# For Fargate clusters, create any needed Fargate profiles
if [[ "${LAUNCH_TYPE}" == "Fargate" ]]; then
    echo "Creating Fargate profiles..."
    create_fargate_profile operators
    create_fargate_profile "${APPLICATION_NAMESPACE}"
    create_fargate_profile "cert-manager"
fi

# Create the WLO_TARGET_NAMESPACE if it doesn't exist
echo "Creating namespaces..."
if [[ -n "${APPLICATION_NAMESPACE}" && "${APPLICATION_NAMESPACE,,}" != "default" ]]; then
    create_namespace "${APPLICATION_NAMESPACE}"
fi

separator

# Add IBM Operator Catalog: https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-adding-operator-catalog
echo "Installing IBM Operator Catalog..."
echo kubectl apply -f $CUR_DIR/templates/catalog_source.yaml
kubectl apply -f $CUR_DIR/templates/catalog_source.yaml
wait_for catalogsource ibm-operator-catalog olm
if [[ $? != 0 ]]; then
    echo "IBM Operator Catalog failed to install."
    exit 1
fi

separator

# Subscribe for Websphere Liberty Operator: https://www.ibm.com/docs/en/was-liberty/nd?topic=operators-installing-kubernetes-cli#in-t-kubectl__install-op-cli
echo "Subscribing for WLO..."
echo kubectl apply -f $CUR_DIR/templates/wlo_subscription.yaml
kubectl apply -f $CUR_DIR/templates/wlo_subscription.yaml

wait_for deployment wlo-controller-manager operators
if [[ $? != 0 ]]; then
    echo "The deployment wlo-controller-manager is not available." >&2
    exit 1
fi

# Generate license Metric param based on Entitlement
#  ["Standalone", "IBM Cloud Pak for Applications", "IBM WebSphere Server Family Edition", "IBM WebSphere Hybrid Edition"]
#  For Standalone license and Family Edition, use metrics PVU
#  For WSHE and CP4Apps, use metrics VPC
LICENSE_METRIC="Virtual Processor Core (VPC)"
if [[ "${LICENSE_ENTITLEMENT}" == "Standalone" || "${LICENSE_ENTITLEMENT}" == "IBM WebSphere Server Family Edition" ]]; then
    LICENSE_METRIC="Processor Value Unit (PVU)"
fi
echo LICENSE_METRIC="'${LICENSE_METRIC}'" >> $CUR_DIR/ibm-liberty-parameters.properties

if [[ "$APPLICATION_DEPLOY" != "None" ]]; then
   # Install cert-manager before installing the application
    separator
    $CUR_DIR/install_cert_manager.sh
    separator

    # Deploy the application
    $CUR_DIR/deploy_application.sh
    separator

    if [[ $DEPLOY != "Passed" ]]; then
        echo "The WebSphereLibertyApplication, ${APPLICATION_NAME}, failed to deploy. Make sure the application image is accessible without a credential. Pod status:" >&2
        kubectl get pods  -n ${APPLICATION_NAMESPACE} | grep  ${APPLICATION_NAME}
    else
        # Deploy a load balancer to expose the application
        $CUR_DIR/deploy_loadbalancer.sh
        separator
    fi
fi

$CUR_DIR/grant_cluster_access.sh

$CUR_DIR/generate_stack_outputs.sh

# Get the WLO deployment status
$CUR_DIR/get-wlo-status.sh
separator

sudo shutdown +2 "IBM WebSphere Liberty installation is complete. \
The system will now shut down in 2 minutes. If you are currently \
using this system, run 'sudo shutdown -c' to stop the shutdown."
