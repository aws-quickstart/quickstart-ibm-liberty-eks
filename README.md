
## quickstart-ibm-liberty-eks

### IBM WebSphere Liberty for Amazon EKS
Use this Partner Solution (formerly Quick Start) to provisions a highly-available architecture that spans two Availability Zones, with an EKS Cluster in each, along with the [WebSphere Liberty Operator](https://ibm.biz/wlo-docs) ready for you to deploy your applications.

 [IBM WebSphere Liberty](https://www.ibm.com/products/websphere-liberty) is a fast, lightweight, modular, and container-friendly cloud-native runtime that supports industry standards such as Java EE, Jakarta EE, and MicroProfile.

### Architecture
Deploying this Quick Start builds the following WebSphere Liberty environment in the AWS Cloud.

**UPDATE Arch diag URL TO before creating the PR**: (https://github.com/quickstart-ibm-liberty-eks/blob/docs/deployment_guide/images/architecture_diagram.png)
![Architecture for IBM WebSphere Liberty for Amazon EKS](https://github.com/git4rk/quickstart-ibm-liberty-eks/blob/re-invent-readme/docs/deployment_guide/images/architecture_diagram.png)


- A virtual private cloud (VPC) configured across two Availability Zones. In each Availability Zone, this solution provisions one public subnet and one private subnet. This creates a logically isolated networking environment that you can connect to your on-premises data centers or use as a standalone environment.
- In the public subnets:
    - Managed network address translation (NAT)gateways to allow outbound internet access for resources in the private subnets.
    - One Availability Zone has a boot node, Amazon Elastic Compute Cloud (Amazon EC2), to access the Amazon EKS cluster. 
- In the private subnets:
    - An EKS cluster with an application pod, WebSphere Liberty Operator, certificate manager, and [Operator Lifecycle Manager](https://olm.operatorframework.io/).
- Amazon CloudWatch to monitor and track metrics for your AWS resources and applications.
- Amazon Elastic Container Registry (Amazon ECR) to store, share, and deploy container software such as application images and artifacts.
- Classic Load Balancer to enable HTTPS access to an application.

### Deploymen options
This Partner Solution provides the following deployment options:
- **Deploy into a new VPC and a new Amazon EKS cluster with an application**:  This option builds a new AWS environment outlined in the architecture diargam. It then deploys WebSphere Liberty Operator, an application, and related artifacts into this EKS cluster. 
- **Deploy into a new VPC and a new Amazon EKS cluster without an application**: This option builds a new AWS environment outlined in the architecture diargam. It then deploys WebSphere Liberty Operator and related artifacts into this EKS cluster. 


### Predeployment steps
Before you launch the Quick Start, see the [AWS QuickStart General Information Guide](https://fwd.aws/rA69w?).

#### Existing license
To use IBM WebSphere Liberty, ensure that you have an active [WebSphere entitlement](https://ibm.biz/was-license) for any of the following products.

- Standalone product editions:
    - IBM WebSphere Application Server
    - IBM WebSphere Application Server Liberty Core
    - IBM WebSphere Application Server NetworkDeployment
- Other product entitlement sources:
    - IBM WebSphere Hybrid Edition
    - IBM Cloud Pak for Applications
    - IBM WebSphere Application Server Family Edition

### Deployment steps
1. Clone the Quick Start templates (including all of its submodules) to your local machine. From the command line, run:
```
git clone --recurse-submodules https://github.com/aws-quickstart/quickstart-ibm-liberty-eks.git
```
2. Install and set up the [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). This tool will allow you to create an S3 bucket and upload content to it.
3. Create an S3 bucket in your region:
```
aws s3 mb s3://<bucket-name> --region <AWS_REGION>
```
4. Go into the parent directory of your local clone of the Quick Start templates and upload all the files to your S3 bucket:
```
aws s3 cp quickstart-ibm-liberty-eks s3://<bucket-name>/quickstart-ibm-liberty-eks --recursive --acl public-read
```
5. Once you’ve uploaded everything, you’re ready to deploy your stack from your S3 bucket. Login to [AWS console](https://aws.amazon.com/) and go to S3 bucket to copy the main template URL.
    1. To deploy into a new VPC and a new Amazon EKS cluster with an application, copy the Object URL of `templates/ibm-liberty-new-eks-with-app.template.yaml`
    2. To Deploy into a new VPC and a new Amazon EKS cluster without an application, copy the Object URL of  `templates/ibm-liberty-new-eks-no-app.template.yaml`
6. From AWS console go to Cloudformation → Create Stack. When specifying a template, paste in the Object URL copied in the previous step.
7. Follow the parameter details to fill in the values and follow UI prompts to create the stack
    1. Provide following values for these parameters:
        - Quick Start S3 bucket name=`<bucket-name>`
        - Quick Start S3 key prefix=quickstart-ibm-liberty-eks/
        - Quick Start S3 bucket Region=`<AWS_REGION>`
8. The stack takes about 20 minutes to deploy. Monitor the stack’s status, and when the status is CREATE_COMPLETE, the IBM WebSphere Liberty for Amazon EKS deployment is ready.
9. To view the created resources, choose the Outputs tab.

### Postdeployment steps
1. [Deploy License Service](https://www.ibm.com/docs/SSHKN6/license-service/1.x.x/standalone-LS.html) on your Kubernetes cluster.License Service is required to measure and track license use of IBM Containerized Software such as WebSphere Liberty application. Manual license measurements are not allowed.
2. If you selected to deploy the sample or a custom application, launch the application. From the Outputs tab of the main stack, click the value of the `AppEndpoint` key

To manually deploy a custom application, [use a
IBM WebSphere Liberty for Amazon EKS on AWS custom resource (CR) file](https://www.ibm.com/docs/SSEQTP_liberty/opr/ae/cfg-t-main.html) that sets parameter values for your application image deployment.

### Troubleshooting
For troubleshooting common Quick Start issues, refer to the [AWS Quick Start General Information Guide](https://fwd.aws/rA69w?) and [Troubleshooting CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html).

### FAQ
Review the [frequently asked questions](docs/FAQ.md) for this solution.

### Customer support
For WebSphere Liberty Operator issues, open a Support Ticket with IBM Support and add information that can help IBM Support troubleshoot and fix the problem.
1. Click **Open a case** on the [WebSphere Application Server support](https://www.ibm.com/mysupport/s/topic/0TO500000001DQQGA2/websphere-application-server) or [Let’s troubleshoot](https://www.ibm.com/mysupport/s/) page.
2. Add information that can help IBM Support determine the cause of the error. In the ticket, describe the error. If the error is difficult to describe, then provide a screen capture of the error. Also, provide pertinent information, such as a description of your cluster configuration and the component that is failing or having issues. 
Review the [frequently asked questions](docs/FAQ.md) to find the deployment logs. See [Gathering information about clusters with MustGather](https://www.ibm.com/docs/SSEQTP_liberty/opr/ae/t-troubleshooting.html#t-troubleshooting__must-gather) to learn how to use MustGather to collect information for a Support Ticket.

### Customer responsibility
After you deploy a Partner Solution, confirm that your resources and services are updated and configured—including any required patches—to meet your security and other needs. For more information, refer to the [Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/).

### Feedback
To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo. 

To submit code for this Quick Start, see the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/).
