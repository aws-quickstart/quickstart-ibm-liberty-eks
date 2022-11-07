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
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

echo
echo Setting up CloudWatch logs
echo MAIN_STACK_NAME : ${MAIN_STACK_NAME}

# Execute yum update
sudo yum update -y

# Install amazon-cloudwatch-agent
sudo yum install amazon-cloudwatch-agent -y

cat <<EOF > /tmp/scripts/config.json
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
                                           "file_path": "/tmp/eksctl.log",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "eksctl.log",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/tmp/deployment.properties",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "deployment.properties",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/tmp/ibm-liberty-app-deploy.yaml",
                                           "log_group_name": "${MAIN_STACK_NAME}",
                                           "log_stream_name": "ibm-liberty-app-deploy.yaml",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/tmp/ibm-liberty-app-deploy-service.yaml",
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

sudo cp /tmp/scripts/config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Trigger CloudWatch agent to watch files to be sent to CloudWatch logs.
sudo mv /tmp/eksctl.log /tmp/eksctl.log.tmp
sudo cat /tmp/eksctl.log.tmp > /tmp/eksctl.log
sudo cat /tmp/scripts/ibm-liberty-parameters.properties | sort > /tmp/deployment.properties

# The app-deploy and -service YAML definitions are copied over empty
# to enable the customer to view and use these templates as-is
sudo cp /tmp/scripts/templates/ibm-liberty-app-deploy.yaml /tmp
sudo cp /tmp/scripts/templates/ibm-liberty-app-deploy-service.yaml /tmp
