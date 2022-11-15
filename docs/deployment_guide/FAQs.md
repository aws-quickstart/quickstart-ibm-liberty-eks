### General FAQs
- [How do I connect to the EKS cluster?](#how-do-i-connect-to-the-eks-cluster)
- [Where are the deployment logs?](#where-are-the-deployment-logs)
- [How do I get information about my deployment?](#how-do-i-get-information-about-my-deployment)
- [How do I recover from a failed stack?](#how-do-i-recover-from-a-failed-stack)

### WebSphere Liberty Operator FAQs
- [What deployments are in a successful installation?](#what-deployments-are-in-a-successful-installation)
- [Where is more information about WebSphere Liberty Operator?](#where-is-more-information-about-websphere-liberty-operator)

### General FAQs

#### How do I connect to the EKS cluster?

The steps to connect to the cluster depend on whether you use the boot node.

##### With the boot node
- Go to the boot node. The boot node is linked to from the _Resources_ tab of the boot node stack. The node ID is listed in _Outputs_ of the main stack.
- Start the boot node.
- Enable SSH to the boot node. Add a rule to the VPC security group that permits inbound traffic on port 22.
- Connect to the boot node with SSH or EC2 Instance Connect in your browser.
- Use `kubectl` commands to manage your cluster.

##### Without the boot node
- Use the [kubernetes cli](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) to access the EKS cluster.
- Run the following command to update your `kubeconfig` file so that you can use `kubectl` commands to work with your cluster.
```
aws eks update-kubeconfig --name <cluster_name> --region <cluster_region>
```

- Replace `<cluster_name>` with your cluster name and `<cluster_region>` with your AWS Region.
- Run any `kubectl` command to confirm that you can access the cluster.
- For example, run `kubectl get pods` and confirm that the output messages show a successful connection to the cluster.
```
$ kubectl get pods
```

An `Unauthorized` error means that your IAM user or role was not granted access to the cluster. To gain access to the cluster, provide your IAM user ARN in the _AdditionalEKSAdminArns_ parameter of the stack.

If needed, ask the creator of the EKS cluster to grant access by adding your IAM user or role to the `aws-auth` Kubernetes ConfigMap in the `kube-system` namespace. This ConfigMap maps IAM entities in AWS to user accounts in the Kubernetes cluster. The following steps use [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html).

- Get the ARN of the IAM entity to which you want to grant cluster access.
    - Example user ARN: `arn:aws:iam::123456789012:user/user@example.com`
    - Example role ARN: `arn:aws:iam::123456789012:role/some-role`
- Run the `eksctl` command to create a mapping for that IAM entity in the `aws-auth` ConfigMap.
```
eksctl create iamidentitymapping --cluster <cluster_name> --region <cluster_region> --arn <arn>
```


#### Where are the deployment logs?

##### CloudWatch log streams
During or after deployment, and even after a failed deployment, you can view log data in https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html[Amazon CloudWatch log streams]. Access log streams from a log groups search in the https://console.aws.amazon.com/cloudwatch/[CloudWatch console].

- In the navigation pane, click *Logs* and then *Log groups*.
- On the Log groups page, enter the stack name in the search bar.
- From the *Log streams* tab of the log group details, select the log stream to view.

After deployment, you can also view log streams from the *Outputs* tab for your CloudFormation stack.

- Click the *Outputs* tab for your main stack.
- Click the value of the _CloudWatchInstallLogs_ key.
- From the *Log streams* tab of the log group details, select the output logs.

##### Lambda function logs
Lambda function logs are at `/aws/lambda/` and have the file path `/aws/lambda/<name_of_lambda_resource>`.

You can view Lambda function logs in CloudWatch.

- From the stack *Resources* tab, select a Lambda function.
- Click the *Monitor* tab.
- Click *View logs in CloudWatch*.

Nested stacks such as _IBMLibertyBootNodeStack_, _IBMLibertyEKSClusterStack_, and _IBMLibertyWorkloadStack_ have a Lambda function.

##### SSM logs
SSM logs are on the boot node at `/var/log/amazon/ssm/`.


#### How do I get information about my deployment?
To get information about {partner-product-short-name} Operator and any deployed applications, run the `kubectl get deployments` command.
```
$ kubectl get deployments
```

For stack outputs, go to the *Outputs* tab for your CloudFormation stack or to the CloudWatch console.

The CloudWatch `deployment.properties` file lists the deployment properties.


#### How do I recover from a failed stack?
Delete the stack and retry the deployment. Stack deletion deletes all the artifacts that the stack created, including the EKS cluster and everything deployed in the cluster.

Stack deletion might fail due to timeouts or resource dependencies. Try to delete the failed stack again. If you installed any external components after the deployment, like Ingress, then those resources are not deleted and might prevent stack deletion. In which case, try to manually delete the resources that prevent stack deletion.


### WebSphere Liberty Operator FAQs

#### What deployments are in a successful installation?
The `kubectl get deployments` command lists the deployments. The application name and its namespace depend on your input. If you did not deploy an application, then no application or cert-manager deployments are in your list.

```
$ kubectl get deployments -A

NAMESPACE    NAME

default      websphereliberty-app-sample
kube-system  coredns
olm          catalog-operator
olm          olm-operator
olm          packageserver
operators    cert-manager
operators    cert-manager-cainjector
operators    cert-manager-webhook
operators    wlo-controller-manager
```


#### Where is more information about WebSphere Liberty Operator?
See the WebSphere Liberty Operator documentation.

- [Viewing operator application status](https://www.ibm.com/docs/SSEQTP_liberty/opr/ae/cfg-t-viewstatus.html)
- [Troubleshooting WebSphere Liberty operators](https://www.ibm.com/docs/SSEQTP_liberty/opr/ae/t-troubleshooting.html)
