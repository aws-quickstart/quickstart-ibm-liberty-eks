#!/bin/bash
set -o pipefail
CUR_DIR="$(cd $(dirname $0) && pwd)"
echo CUR_DIR=${CUR_DIR}
source $CUR_DIR/ibm-liberty-parameters.properties

echo "**********************************************"
echo "*         Deployment Status Summary          *"
echo "**********************************************"
echo
echo ----------------- Properties ------------------
echo "Content of " $CUR_DIR/ibm-liberty-parameters.properties
cat $CUR_DIR/ibm-liberty-parameters.properties
echo ----------------- cert-manger CRD ------------------
kubectl get crds |grep cert-manager
echo
echo ------- WebSphere Liberty Operator Deployment ---------
kubectl get deployments --namespace operators|grep wlo-controller-manager
echo
echo ------------- WebSphere Liberty Operator CRD ----------
kubectl get crds |grep websphereliberty
echo
if [[ "$APPLICATION_DEPLOY" != "None" ]]; then
    echo -------- WebSphere Liberty Application Service --------
    kubectl get services --namespace ${APPLICATION_NAMESPACE} -o wide |grep ${APPLICATION_NAME}
    echo
    echo ------------ WebSphere Liberty Application -------------
    kubectl get pods --namespace ${APPLICATION_NAMESPACE}|grep ${APPLICATION_NAME} |grep Running
    echo
    echo ------------ WebSphere Liberty Application URL -------------
    echo "${APPLICATION_ENDPOINT_URL}"
    echo ------------------------------------------------------------
fi


#kubectl  --namespace ${APPLICATION_NAMESPACE}  exec  ${WLO_APP_POD}  -- curl https://${APPLICATION_ENDPOINT} -silent -k > /tmp//wlo-sample-output.log

#WLO_SAMPLE_TITLE=`kubectl --namespace ${APPLICATION_NAMESPACE}   exec  ${WLO_APP_POD}  -- curl -silent -k https://${APPLICATION_ENDPOINT} |grep  "Open Liberty - Getting Started Sample" |awk -F"<title>" '{ print $ 2}' | awk -F"</title>" '{ print $ 1}'`
#WLO_SAMPLE_TITLE=`curl -silent -k https://${APPLICATION_ENDPOINT} |grep  "Open Liberty - Getting Started Sample" |awk -F"<title>" '{ print $ 2}' | awk -F"</title>" '{ print $ 1}'`
#echo WLO Sample Title is \"$WLO_SAMPLE_TITLE\"
#echo
