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


args=("$@")
readonly argLength="$#"

readonly CLIENT_DIR=${args[0]}
readonly BATCH_SIZE=${args[1]}
readonly THREAD_COUNT=${args[2]}
readonly INTERVAL=${args[3]} #Time between batches
readonly TEST_DURATION=${args[4]}
readonly WINDOW_SIZE=${args[5]}
readonly NODE_ID_1=${args[6]}
readonly REMOTE_IP1=${args[7]}
readonly PORT1=${args[8]}
readonly REMOTE_USERNAME1=${args[9]}
readonly NODE_ID_2=${args[10]}
readonly REMOTE_IP2=${args[11]}
readonly PORT2=${args[12]}
readonly REMOTE_USERNAME2=${args[13]}
readonly KEY=${args[14]}
readonly PRODUCT_VERSION=${args[15]}

readonly INSTALLATION_DIR=/home/ubuntu/distribution
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
readonly LOAD_AVG_1_MIN="Load Average - Last 1 minute"
readonly LOAD_AVG_5_MIN="Load Average - Last 5 minutes"
readonly LOAD_AVG_15_MIN="Load Average - Last 15 minutes"
readonly WINDOW_SIZE_HEADER="Window size"
readonly BATCH_SIZE_HEADER="Batch size"
readonly SCENARIO_HEADER="Scenario"

readonly SIDDHI_APP_STATUS_REST_PATH="siddhi-apps/TCP_Benchmark/status"
readonly SERVER_1_HTTPS_PORT="9443"
readonly SERVER_2_HTTPS_PORT="9444"

readonly PRODUCT_NAME=wso2sp

readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"
readonly PUBLISHING_CLIENT_DIR="${ARTIFACT_REPO_NAME}/clients"
readonly PUBLISHING_CLIENT_JAR_NAME="performance-tcp-client-5-jar-with-dependencies.jar"
readonly RESULT_DIR_NAME=sp-performance-test-results

readonly PERFORMANCE_RESULTS_REPO=git@github.com:minudika/sp-performance-test-results.git
readonly DOWNLOAD_PATH=${CLIENT_DIR}/${RESULT_DIR_NAME}
readonly SUMMARY_FILE_NAME=summary.csv
readonly SUMMARY_FILE_PATH=${DOWNLOAD_PATH}/summary.csv
readonly REPORT_LOCATION=${CLIENT_DIR}/metrics

print_parameters() {
echo "
1. Client home : ${CLIENT_DIR}
2. Batch size : ${BATCH_SIZE}
3. Thread count : ${THREAD_COUNT}
4. Interval : ${INTERVAL}
5. Test duration : ${TEST_DURATION}
6. Window size : ${WINDOW_SIZE}
7. Node id 1 : ${NODE_ID_1}
8. REMOTE IP 1 : ${REMOTE_IP1}
9. PORT 1 : ${PORT1}
10. REMOTE_USERNAME 1: ${REMOTE_USERNAME1}
11. Node id 2 : ${NODE_ID_2}
12. REMOTE IP 2: ${REMOTE_IP2}
13. PORT 2 : ${PORT2}
14. REMOTE_USERNAME 2: ${REMOTE_USERNAME2}
15. KEY : ${KEY}
16. Product version : ${PRODUCT_VERSION}
"
}

ssh_add() {
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/ssh-key
}

clone_artifacts() {
    mkdir -p ${CLIENT_DIR}
    cd ${CLIENT_DIR}
    ssh_add
    echo "Cloning performance test artifacts.."
    git clone ${SIDDHI_APP_REPO_URL}
}

start_sever_1() {
    echo "Starting the server ${REMOTE_IP1}.."
    echo "sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/setup-sp.sh ${SCENARIO} ${WINDOW_SIZE} ${NODE_ID_1} ${INSTALLATION_DIR} ${PRODUCT_VERSION}"
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/setup-sp.sh ${SCENARIO} ${WINDOW_SIZE} ${NODE_ID_1} ${INSTALLATION_DIR} ${PRODUCT_VERSION}
}

start_sever_2() {
    echo "Starting the server ${REMOTE_IP2}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./distribution/setup-sp.sh ${SCENARIO} ${WINDOW_SIZE} ${NODE_ID_2} ${INSTALLATION_DIR} ${PRODUCT_VERSION}
}

shutdown_server_1() {
    echo "Shutting down the server.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/shutdown-sp.sh
}

shutdown_server_2() {
    echo "Shutting down the server.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./distribution/shutdown-sp.sh
}

clone_results_repo() {
    cd ${CLIENT_DIR}
    ssh_add
    git clone ${PERFORMANCE_RESULTS_REPO}
    cd ${RESULT_DIR_NAME}
    rm -f ${SUMMARY_FILE_NAME}
}

download_results() {
    cd ${RESULT_DIR_NAME}
    mkdir ${SCENARIO}
    echo "Downloading result set.."
    sudo scp -r -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}:${INSTALLATION_DIR}/wso2sp-4.3.0/wso2/worker/performance-results/ \
    ${DOWNLOAD_PATH}/${SCENARIO}
}

zip_downloaded_results() {
    cd ${CLIENT_DIR}
    echo "Compressing downloaded results into ${RESULT_DIR_NAME}.zip"
    zip -r ${RESULT_DIR_NAME}.zip ${RESULT_DIR_NAME}
}

create_summary_file() {
    header="${SCENARIO_HEADER},${BATCH_SIZE_HEADER},${WINDOW_SIZE_HEADER},${TOTAL_ELAPSED_TIME},${TOTAL_EVENT_COUNT},\
    ${ENTIRE_THROUGHPUT},${ENTIRE_AVG_LATENCY},${AVG_LATENCY_90},${AVG_LATENCY_95},${AVG_LATENCY_99},\
    ${LOAD_AVG_1_MIN},${LOAD_AVG_5_MIN},${LOAD_AVG_15_MIN}"

    if [ ! -f ${SUMMARY_FILE_PATH} ]; then
        echo "Creating summary file"
        echo "${header}" >> ${SUMMARY_FILE_PATH}
    fi
}

get_server_metrics() {
    echo "Collecting server metrics from $server."
    mkdir ${REPORT_LOCATION}
    export LC_TIME=C
    command_prefix="sudo ssh -i ${KEY} -o SendEnv=LC_TIME ubuntu@192.168.57.25"
    ${command_prefix} ss -s >${REPORT_LOCATION}/${REMOTE_IP1}_ss.txt
    ${command_prefix} uptime >${REPORT_LOCATION}/${REMOTE_IP1}_uptime.txt
    ${command_prefix} sar -q >${REPORT_LOCATION}/${REMOTE_IP1}_loadavg.txt
    ${command_prefix} sar -A >${REPORT_LOCATION}/${REMOTE_IP1}_sar.txt
    ${command_prefix} top -bn 1 >${REPORT_LOCATION}/${REMOTE_IP1}_top.txt
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
    get_server_metrics

    avgValues=$(tail -2 ${REPORT_LOCATION}/${REMOTE_IP1}_loadavg.txt | head -1)

    loadAvgs=( $avgValues )
    echo "Summarizing performance results of ${scenario_name} test.."
    while IFS=, read -r col0 col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13
    do
        value="${scenario_name},${BATCH_SIZE},${WINDOW_SIZE},${col3},${col4},${col2},${col7},${col8},${col9},${col10},\
        ${loadAvgs[3]},${loadAvgs[4]},${loadAvgs[5]}"
    done < <(tail -n 1 ${DOWNLOAD_PATH}/${SCENARIO}/${PERFORMANCE_RESULTS}/${PERFORMANCE_RESULTS_FILE_NAME})

    echo ${value} >> ${SUMMARY_FILE_PATH}
}

push_results_to_git() {
    cd ${DOWNLOAD_PATH}
    current_date_time="`date "+%Y-%m-%d %H:%M:%S"`";
    git remote add origin ${PERFORMANCE_RESULTS_REPO}
    git add summary.csv
    git commit -m "${current_date_time} : Add performance results" -m "Test duration : ${TEST_DURATION}"
    echo "${current_date_time}: pushing test results to '${PERFORMANCE_RESULTS_REPO}'"
    git push -u origin master
}

compress_result_set() {
    echo "Creating results.zip.."
    zip -rq results.zip ${DISTRIBUTION_NAME}/
}

clean_server_1() {
    echo "Removing performance results and siddhi apps from worker ${REMOTE_IP1}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/clean.sh
}

clean_server_2() {
    echo "Removing performance results and siddhi apps from worker ${REMOTE_IP2}.."
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./distribution/clean.sh
}

wait_until_deploy_on_server_1() {
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
}

wait_until_deploy_on_server_2() {
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

    cd ${PUBLISHING_CLIENT_DIR}
    echo "[${current_date_time}] Executing tcp client.."
    java \
        -Dhost=${REMOTE_IP1}\
        -Dport=${PORT1}\
        -Dbatch.size=${BATCH_SIZE}\
        -Dinterval=${INTERVAL}\
        -Dduration=${TEST_DURATION}\
        -Dthread.count=${THREAD_COUNT}\
        -Dscenario=${SCENARIO}\
        -jar ${PUBLISHING_CLIENT_JAR_NAME}\
        /
}

run_tests() {
    for (( i=16 ; i<${argLength}; i++ ))
    do
        local scenario=${args[i]}
        echo "***************************************************"
        echo "Running performance test for scenario : ${scenario}"
        echo "***************************************************"
        #starting server 1
        echo "Starting the server ${REMOTE_IP1}.."
        echo "sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/setup-sp.sh ${scenario} ${WINDOW_SIZE} ${NODE_ID_1} ${INSTALLATION_DIR} ${PRODUCT_VERSION}"
        sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1} ./distribution/setup-sp.sh ${scenario} ${WINDOW_SIZE} ${NODE_ID_1} ${INSTALLATION_DIR} ${PRODUCT_VERSION}
        wait_until_deploy_on_server_1

        #starting server 1
        echo "Starting the server ${REMOTE_IP2}.."
        sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2} ./distribution/setup-sp.sh ${scenario} ${WINDOW_SIZE} ${NODE_ID_2} ${INSTALLATION_DIR} ${PRODUCT_VERSION}
        wait_until_deploy_on_server_2

        current_date_time="`date "+%Y-%m-%d %H:%M:%S"`";

        # execute java client for publishing messages
        cd ${CLIENT_DIR}
        cd ${PUBLISHING_CLIENT_DIR}
        echo "[${current_date_time}] Executing tcp client.."
        java \
            -Dhost=${REMOTE_IP1}\
            -Dport=${PORT1}\
            -Dbatch.size=${BATCH_SIZE}\
            -Dinterval=${INTERVAL}\
            -Dduration=${TEST_DURATION}\
            -Dthread.count=${THREAD_COUNT}\
            -Dscenario=$scenario\
            -jar ${PUBLISHING_CLIENT_JAR_NAME}\
            /

            #download_results
            cd ${CLIENT_DIR}/${RESULT_DIR_NAME}
            mkdir ${scenario}
            echo "Downloading result set.."
            sudo scp -r -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}:${INSTALLATION_DIR}/wso2sp-4.3.0/wso2/worker/performance-results/ \
            ${DOWNLOAD_PATH}/${scenario}

            #summarize results
            sudo chmod 755 ${DOWNLOAD_PATH}
            case ${scenario} in
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
            get_server_metrics

            avgValues=$(tail -2 ${REPORT_LOCATION}/${REMOTE_IP1}_loadavg.txt | head -1)

            loadAvgs=( $avgValues )
            echo "Summarizing performance results of ${scenario_name} test.."
            while IFS=, read -r col0 col1 col2 col3 col4 col5 col6 col7 col8 col9 col10 col11 col12 col13
            do
                value="${scenario_name},${BATCH_SIZE},${WINDOW_SIZE},${col3},${col4},${col2},${col7},${col8},${col9},${col10},\
                ${loadAvgs[3]},${loadAvgs[4]},${loadAvgs[5]}"
            done < <(tail -n 1 ${DOWNLOAD_PATH}/${scenario}/${PERFORMANCE_RESULTS}/${PERFORMANCE_RESULTS_FILE_NAME})

            echo ${value} >> ${SUMMARY_FILE_PATH}

            clean_server_1
            clean_server_2
        done
}

main() {
   print_parameters
   clone_artifacts
   clone_results_repo
#   start_sever_1
#   wait_until_deploy_on_server_1
#   start_sever_2
#   wait_until_deploy_on_server_2
#   execute_client
#   shutdown_server_1
#   shutdown_server_2
#   download_results
    run_tests
   push_results_to_git
   zip_downloaded_results

}

main