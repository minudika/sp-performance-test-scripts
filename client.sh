#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

readonly PRODUCT_NAME=wso2sp
readonly PRODUCT_VERSION=4.3.0
readonly INSTALLATION_DIR=/home/ubuntu
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"

readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"

readonly KEY="/home/minudika/Projects/WSO2/dev/resources/keys/ssh-key"

readonly CLIENT_DIR=$1
readonly BATCH_SIZE=$2
readonly THREAD_COUNT=$3
readonly INTERVAL=$4 #Time between batches
readonly TEST_DURATION=$5
readonly SCENARIO=$6
readonly WINDOW_SIZE=$7
readonly REMOTE_IP1=${8}
readonly PORT1=$9
readonly REMOTE_USERNAME1=${10}
readonly REMOTE_IP2=${11}
readonly PORT2=${12}
readonly REMOTE_USERNAME2=${13}

print_instructions() {
echo "
1. Client home : ${CLIENT_DIR}
2. Batch size : ${BATCH_SIZE}
3. Thread count : ${THREAD_COUNT}
4. Interval : ${INTERVAL}
5. Test duration : ${TEST_DURATION}
6. Scenario : ${SCENARIO}
7. Window size : ${WINDOW_SIZE}
8. REMOTE IP 1 : ${REMOTE_IP1}
9. PORT 1 : ${PORT1}
10. REMOTE_USERNAME 1: ${REMOTE_USERNAME1}
11. REMOTE IP 2: ${REMOTE_IP2}
12. PORT 2 : ${PORT2}
13. REMOTE_USERNAME 2: ${REMOTE_USERNAME2}

"
}

clone_artifacts() {
    mkdir -p ${CLIENT_DIR}
    cd ${CLIENT_DIR}
    echo "Cloning performance test artifacts.."
    git clone ${SIDDHI_APP_REPO_URL}
}

start_sever_1() {
    echo "starting the server ${REMOTE_IP1}.."
    ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./setup-sp.sh ${SCENARIO}
}

start_sever_2() {
    echo "starting the server ${REMOTE_IP2}.."
    ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./setup-sp.sh ${SCENARIO}
}

shutdown_server_1() {
    echo "shutting down the server.."
    ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./shutdown-sp.sh
}

shutdown_server_2() {
    echo "shutting down the server.."
    ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./shutdown-sp.sh
}

download_results() {
    cd ${INSTALLATION_DIR}/
    mkdir ${SCENARIO}
    echo "downloading result set.."
    scp -r -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}:/home/ubuntu/wso2sp-4.3.0/wso2/worker/performance-results/ \
    /home/minudika/Projects/WSO2/dev/performance-test/downloaded-results
}

wait_until_deploy_on_server_1() {
echo "waiting until siddhi app getting deployed on server ${REMOTE_IP1}.."
while
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X GET \
    https://${REMOTE_IP1}:9443/siddhi-apps/TCP_Benchmark/status -H "accept: application/json" -u admin:admin -k)

    sleep 1
    ((${status_code} != 200 ))
do :; done
echo "siddhi app has been deployed successfully on on server ${REMOTE_IP1}"
sleep 5
}

wait_until_deploy_on_server_2() {
echo "waiting until siddhi app getting deployed on server ${REMOTE_IP2}.."
while
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X GET \
    https://${REMOTE_IP2}:9443/siddhi-apps/TCP_Benchmark/status -H "accept: application/json" -u admin:admin -k)

    sleep 1
    ((${status_code} != 200 ))
do :; done
echo "siddhi app has been deployed successfully on on server ${REMOTE_IP2}"
sleep 5
}

run_tcp_client_with_persistance_disabled() {
    cd /home/minudika/Projects/WSO2/pack/sp/4.3.0/rc3/wso2sp-4.3.0/samples/sample-clients/tcp-client/target
    echo "Executing tcp client.."
    java \
        -Dhost=${REMOTE_IP1}\
        -Dport=${PORT1}\
        -Dbatch.size=${BATCH_SIZE}\
        -Dinterval=${INTERVAL}\
        -Dduration=${TEST_DURATION}\
        -Dthread.count=${THREAD_COUNT}\
        -Dpersistence.enabled=false\
        -jar performance-tcp-client-5-jar-with-dependencies.jar\
        /
}


run_tcp_client_with_persistance_enabled() {
    cd ${CLIENT_DIR}/${ARTIFACT_REPO_NAME}/clients
    echo "Executing tcp client.."
    java \
        -Dhost=${REMOTE_IP1}\
        -Dport=${PORT1}\
        -Dbatch.size=${BATCH_SIZE}\
        -Dinterval=${INTERVAL}\
        -Dduration=${TEST_DURATION}\
        -Dthread.count=${THREAD_COUNT}\
        -Dpersistence.enabled=true\
        -jar performance-tcp-client-5-jar-with-dependencies.jar\
        /
}

execute_client() {
    if [[ ${SCENARIO} > 6 ]]; then
        run_tcp_client_with_persistance_enabled
    else
        run_tcp_client_with_persistance_disabled
    fi
}

ssh_copy() {
   ssh-copy-id -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}
}

main() {
   ssh_copy
   print_instructions
   clone_artifacts
   start_sever_1
   wait_until_deploy_on_server_1
   start_sever_2
   wait_until_deploy_on_server_2
   execute_client
   shutdown_server_1
   shutdown_server_2
   download_results
}

main

