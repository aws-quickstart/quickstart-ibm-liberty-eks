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

DEPLOY="Passed"

separator() {
    echo "--------------------------------------------------------------------------------------"
}

wait_for() {
    type=$1
    name=$2
    namespace=${3:-default}

    MAX_RETRIES=199
    count=0

    echo "Waiting for ${type} ${name} to be ready..."
    kubectl get ${type} ${name} -n ${namespace}

    while [ $? -ne 0 ]; do
        if [ $count -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to maximum retires reached."
            return 1
        fi

        count=$((count+1))

        echo "Unable to get ${type} ${name}: retry ${count} of ${MAX_RETRIES}."
        sleep 5s
        kubectl get ${type} ${name} -n ${namespace}
    done

    echo "The ${type} ${name} is ready."

    if [[ "${type}" == *"deploy"* ]]; then
        echo "Waiting for deployment ${name} pods to be ready..."
        count=0
        podStatus="$(kubectl get deploy ${name} -n ${namespace} -o=jsonpath='{.status.readyReplicas}{"/"}{.status.replicas}')"
        readyPods="$(echo $podStatus | cut -d / -f 1)"
        desiredPods="$(echo $podStatus | cut -d / -f 2)"

        while [[ "${readyPods}" -ne "${desiredPods}" ]]; do
            if [ $count -eq $MAX_RETRIES ]; then
                echo "Timeout and exit due to maximum retires reached."
                return 1
            fi

            count=$((count+1))

            echo "${readyPods:-0}/${desiredPods} ready for deployment ${name}. Retry ${count} of ${MAX_RETRIES}."
            sleep 5s
            podStatus="$(kubectl get deploy ${name} -n ${namespace} -o=jsonpath='{.status.readyReplicas}{"/"}{.status.replicas}')"
            readyPods="$(echo $podStatus | cut -d / -f 1)"
            desiredPods="$(echo $podStatus | cut -d / -f 2)"
        done

        echo "All pods ready for deployment ${name}."
    fi

    if [[ "${type}" == "service" || "${type}" == "svc" ]]; then
        echo "Waiting for service ${name} ingress to be ready..."
        curl -k -silent https://$svcEndpoint  >  svcEndpoint.log
        curl_return=$?
        count=0
        svcEndpoint="$(kubectl get service ${name} -n ${namespace} -o=jsonpath='{.status.loadBalancer.ingress[*].hostname}')"

        while [[ $? != 0 || -z "${svcEndpoint}" || $curl_return != 0 ]]; do
            if [ $count -eq $MAX_RETRIES ]; then
                echo "Timeout and exit due to maximum retires reached."
                return 1
            fi

            count=$((count+1))

            echo "Failed to get ingress endpoint for service ${name}. Retry ${count} of ${MAX_RETRIES}."
            sleep 5s
            curl -k -silent https://$svcEndpoint  >  svcEndpoint.log
            curl_return=$?
            svcEndpoint="$(kubectl get service ${name} -n ${namespace} -o=jsonpath='{.status.loadBalancer.ingress[*].hostname}')"
        done

        echo "All pods ready for deployment ${name}."
    fi
}
