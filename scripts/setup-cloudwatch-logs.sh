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
# Websphere Liberty Operator on AWS
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

echo
echo Setting up CloudWatch logs
echo MainStackName : ${MainStackName}

# Execute yum update
sudo yum update -y

# Install amazon-cloudwatch-agent
sudo yum install amazon-cloudwatch-agent -y
sleep 10s

cat <<EOF > /tmp/scripts/config.json
{
        "agent": {
                "run_as_user": "${BootNodeUser}"
        },
        "logs": {
                "logs_collected": {
                        "files": {
                          "collect_list": [
                                   {
                                           "file_path": "${Install_Log_Location}",
                                           "log_group_name": "${MainStackName}",
                                           "log_stream_name": "install-log",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/tmp/eksctl_create_cluster.log",
                                           "log_group_name": "${MainStackName}",
                                           "log_stream_name": "eksctl_create_cluster-log",
                                           "retention_in_days": -1
                                   },
                                   {
                                           "file_path": "/tmp/output.properties",
                                           "log_group_name": "${MainStackName}",
                                           "log_stream_name": "output-properties",
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

# Trigger CloudWatch logs for create EKS Cluster log.
sleep 5s
sudo mv /tmp/eksctl_create_cluster.log /tmp/eksctl_create_cluster.log.tmp
sudo cat /tmp/eksctl_create_cluster.log.tmp > /tmp/eksctl_create_cluster.log
sudo cp /tmp/scripts/ibm-liberty-parameters.properties /tmp/output.properties
