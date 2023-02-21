#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

echo
echo Setting up CloudWatch logs
echo MAIN_STACK_NAME : ${MAIN_STACK_NAME}

# Execute yum update
sudo yum update -y

# Install amazon-cloudwatch-agent
sudo yum install amazon-cloudwatch-agent -y

cat <<EOF > /opt/ibm/scripts/config.json
{
        "agent": {
                "run_as_user": "${BOOTNODE_USER}"
        },
        "logs": {
                "logs_collected": {
                        "files": {
                          "collect_list": [
                                   {
                                           "file_path": "${INSTALL_LOG_LOCATION}",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "install.log",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/opt/ibm/eksctl.log",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "eksctl.log",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/opt/ibm/deployment.properties",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "deployment.properties",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/opt/ibm/ibm-liberty-app-deploy.yaml",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "ibm-liberty-app-deploy.yaml",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/opt/ibm/ibm-liberty-app-deploy-service.yaml",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "ibm-liberty-app-deploy-service.yaml",
                                           "retention_in_days": -1
                                   }
                           ]
                   }
           }
   }
}
EOF

sudo cp /opt/ibm/scripts/config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Trigger CloudWatch agent to watch files to be sent to CloudWatch logs.
sudo mv /opt/ibm/eksctl.log /opt/ibm/eksctl.log.tmp
sudo cat /opt/ibm/eksctl.log.tmp > /opt/ibm/eksctl.log
sudo cat /opt/ibm/scripts/ibm-liberty-parameters.properties | sort > /opt/ibm/deployment.properties

# The app-deploy and -service YAML definitions are copied over empty
# to enable the customer to view and use these templates as-is
sudo cp /opt/ibm/scripts/templates/ibm-liberty-app-deploy.yaml /opt/ibm
sudo cp /opt/ibm/scripts/templates/ibm-liberty-app-deploy-service.yaml /opt/ibm
