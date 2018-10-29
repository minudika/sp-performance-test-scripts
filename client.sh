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

readonly SCENARIO_PASSTHROUGH=1
readonly SCENARIO_FILTER=2
readonly SCENARIO_PATTERNS=3
readonly SCENARIO_PARTITIONS=4
readonly SCENARIO_WINDOW_LARGE=5
readonly SCENARIO_WINDOW_SMALL=6
readonly SCENARIO_PERSISTENCE_MYSQL_INSERT=7
readonly SCENARIO_PERSISTENCE_MYSQL_UPDATE=8
readonly SCENARIO_PERSISTENCE_MSSQL_INSERT=9
readonly SCENARIO_PERSISTENCE_MSSQL_UPDATE=10
readonly SCENARIO_PERSISTENCE_ORACLE_INSERT=11
readonly SCENARIO_PERSISTENCE_ORACLE_UPDATE=12
readonly PERFORMANCE_RESULTS="performance-results"
readonly PERFORMANCE_RESULTS_FILE_NAME="output.csv"

readonly TOTAL_ELAPSED_TIME="Total elapsed time(s)"
readonly TOTAL_EVENT_COUNT="Total event count"
readonly ENTIRE_THROUGHPUT="Entire throughput for the run (thousands events/second)"
readonly ENTIRE_AVG_LATENCY="Entire Average latency per event for the run(ms)"
readonly AVG_LATENCY_90="AVG latency from start (90)"
readonly AVG_LATENCY_95="AVG latency from start (95)"
readonly AVG_LATENCY_99="AVG latency from start (99)"
readonly WINDOW_SIZE_HEADER="Window size"
readonly BATCH_SIZE_HEADER="Batch size"
readonly SCENARIO_HEADER="Scenario"

readonly SIDDHI_APP_STATUS_REST_PATH="siddhi-apps/TCP_Benchmark/status"
readonly SERVER_1_HTTPS_PORT="9443"
readonly SERVER_2_HTTPS_PORT="9444"

readonly PRODUCT_NAME=wso2sp
readonly PRODUCT_VERSION=4.3.0
readonly INSTALLATION_DIR=/home/ubuntu
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"

readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly CLIENT_DIR_NAME="clients"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"
readonly PERFORMANCE_RESULTS_REPO=git@github.com:minudika/sp-performance-test-results.git

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
readonly KEY=${14}

readonly DOWNLOAD_DIR_NAME=downloaded-results
readonly DOWNLOAD_PATH=${CLIENT_DIR}/${DOWNLOAD_DIR_NAME}
readonly SUMMARY_FILE_NAME=summary.csv
readonly SUMMARY_FILE_PATH=${DOWNLOAD_PATH}/summary.csv


print_parameters() {
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

start_severs() {
    echo "Starting the server ${REMOTE_IP1}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./setup-sp.sh ${SCENARIO}

    echo "Starting the server ${REMOTE_IP2}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./setup-sp.sh ${SCENARIO}
}


shutdown_servers() {
    echo "Shutting down the server ${REMOTE_IP1}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./shutdown-sp.sh

    echo "Shutting down the server ${REMOTE_IP2}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./shutdown-sp.sh
}

download_results() {
    cd ${CLIENT_DIR}
    mkdir ${DOWNLOAD_DIR_NAME}
    cd ${DOWNLOAD_DIR_NAME}
    mkdir ${SCENARIO}
    echo "Downloading result set from ${REMOTE_IP1}.."
    sudo scp -r -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}:/home/ubuntu/wso2sp-4.3.0/wso2/worker/performance-results/ \
    ${DOWNLOAD_PATH}/${SCENARIO}
}

create_summary_file() {
    header="${SCENARIO_HEADER},${BATCH_SIZE_HEADER},${WINDOW_SIZE_HEADER},${TOTAL_ELAPSED_TIME},${TOTAL_EVENT_COUNT},\
    ${ENTIRE_THROUGHPUT},${ENTIRE_AVG_LATENCY},${AVG_LATENCY_90},${AVG_LATENCY_95},${AVG_LATENCY_99}"

    if [ ! -f ${SUMMARY_FILE_PATH} ]; then
        echo "Creating summary file"
        echo "${header}" >> ${SUMMARY_FILE_PATH}
    fi
}

summarize() {
sudo chmod 755 ${DOWNLOAD_PATH}
case ${SCENARIO} in
        ${SCENARIO_PASSTHROUGH})
            scenario_name="Simple Passthrough";;
        ${SCENARIO_FILTER})
            scenario_name="Filter";;
        ${SCENARIO_PATTERNS})
            scenario_name="Patterns";;
        ${SCENARIO_PARTITIONS})
            scenario_name="Partitions";;
        ${SCENARIO_WINDOW_LARGE})
            scenario_name="Large Window";;
        ${SCENARIO_WINDOW_SMALL})
            scenario_name="Small Window";;
        ${SCENARIO_PERSISTENCE_MYSQL_INSERT})
            scenario_name="MySQL Insert";;
        ${SCENARIO_PERSISTENCE_MYSQL_UPDATE})
            scenario_name="MySQL Insert or Update";;
        ${SCENARIO_PERSISTENCE_MSSQL_INSERT})
            scenario_name="MSSQL Insert";;
        ${SCENARIO_PERSISTENCE_MSSQL_UPDATE})
            scenario_name="MSSQL Insert or Update";;
        ${SCENARIO_PERSISTENCE_ORACLE_INSERT})
            scenario_name="OracleDB Insert";;
        ${SCENARIO_PERSISTENCE_ORACLE_UPDATE})
            scenario_name="OracleDB Update";;
    esac

    create_summary_file

    echo "Summarizing performance results of ${scenario_name} test.."
    while IFS=, read -r col0 col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13
    do
        value="${scenario_name},${BATCH_SIZE},${WINDOW_SIZE},${col3},${col4},${col2},${col7},${col8},${col9},${col10}"
    done < <(tail -n 1 ${DOWNLOAD_PATH}/${SCENARIO}/${PERFORMANCE_RESULTS}/${PERFORMANCE_RESULTS_FILE_NAME})

    echo ${value} >> ${SUMMARY_FILE_PATH}
}

push_results_to_git() {
    cd ${DOWNLOAD_PATH}
    git init
    current_date_time="`date "+%Y-%m-%d %H:%M:%S"`";
    git remote add origin ${PERFORMANCE_RESULTS_REPO}
    git add -A
    git commit -m "${current_date_time} : Add performance results" -m "Test duration : ${TEST_DURATION}"
    echo "${current_date_time}: Pushing test results to '${PERFORMANCE_RESULTS_REPO}'"
    git push -u origin master
}

clean_servers() {
    echo "Removing performance results and siddhi apps from worker ${REMOTE_IP1}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./clean.sh

    echo "Removing performance results and siddhi apps from worker ${REMOTE_IP2}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./clean.sh
}

wait_until_deploy_on_servers() {
echo "Waiting until siddhi app getting deployed on server ${REMOTE_IP1}.."
while
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X GET \
    https://${REMOTE_IP1}:${SERVER_1_HTTPS_PORT}/${SIDDHI_APP_STATUS_REST_PATH}\
     -H "accept: application/json"\
     -u admin:admin -k)

    sleep 1
    ((${status_code} != 200 ))
do :; done
echo "Siddhi app has been deployed successfully on on server ${REMOTE_IP1}"
sleep 5

echo "Waiting until siddhi app getting deployed on server ${REMOTE_IP2}.."
while
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X GET \
    https://${REMOTE_IP2}:${SERVER_2_HTTPS_PORT}/${SIDDHI_APP_STATUS_REST_PATH}\
     -H "accept: application/json"\
     -u admin:admin -k)

    sleep 1
    ((${status_code} != 200 ))
do :; done
echo "Siddhi app has been deployed successfully on on server ${REMOTE_IP2}"
sleep 5
}


execute_client() {
    current_date_time="`date "+%Y-%m-%d %H:%M:%S"`";

    cd ${CLIENT_DIR}/${ARTIFACT_REPO_NAME}/${CLIENT_DIR_NAME}
    echo "[${current_date_time}] Executing tcp client.."
    java \
        -Dhost=${REMOTE_IP1}\
        -Dport=${PORT1}\
        -Dbatch.size=${BATCH_SIZE}\
        -Dinterval=${INTERVAL}\
        -Dduration=${TEST_DURATION}\
        -Dthread.count=${THREAD_COUNT}\
        -Dscenario=${SCENARIO}\
        -jar performance-tcp-client-5-jar-with-dependencies.jar\
        /
}


main() {
   print_parameters
   clone_artifacts
   start_severs
   wait_until_deploy_on_servers
   execute_client
   shutdown_servers
   shutdown_servers
   download_results
   summarize
   push_results_to_git
   clean_servers
}

main

