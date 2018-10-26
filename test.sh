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
readonly INSTALLATION_DIR=/home/minudika/Projects/WSO2/dev/performance-test
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"

# databases
readonly WSO2_UM_DB="WSO2_UM_DB"
readonly WSO2_REG_DB="WSO2_REG_DB"
readonly WSO2_ANALYTICS_EVENT_STORE="WSO2_ANALYTICS_EVENT_STORE_DB"
readonly WSO2_ANALYTICS_PROCESSED_DATA_STORE="WSO2_ANALYTICS_PROCESSED_DATA_STORE_DB"
readonly WSO2_AM_STATS_DB="WSO2_AM_STATS_DB"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"

readonly SIDDHI_APP_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${SIDDHI_APP_REPO_NAME}"
readonly SIDDHI_APP_DIR="${INSTALLATION_DIR}/${SIDDHI_APP_REPO_NAME}/artifacts"
readonly CLIENT_DIR="${INSTALLATION_DIR}/${SIDDHI_APP_REPO_NAME}/clients"

readonly SP_ZIP_LOCATION=""

readonly MYSQL_USERNAME=root
readonly MYSQL_PASSWORD=root

readonly SCENARIO=$1
readonly WINDOW_SIZE=$2

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

clone_artifacts() {
    mkdir -p ${INSTALLATION_DIR}
    cd ${INSTALLATION_DIR}
    echo "Cloning performance test artifacts"
    git clone ${SIDDHI_APP_REPO_URL}
}

setup_mysql_database() {
    echo "setting up database"
    mysql -u root -proot -e "CREATE DATABASE StreamProcessor; USE StreamProcessor;"
}

copy_passthrough_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "simplePassthrough/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
    echo "Passthrough siddhi app copied."
}

copy_mysql_insert_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/Mysql/Insert/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_mysql_update_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/Mysql/Update/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_Filter_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Filter/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_partitions_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "partitions/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_patterns_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "patterns/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_large_window_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "window/large_window/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_small_window_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "window/small_window/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_siddhiApp() {
    case $SCENARIO in
        ${SCENARIO_PASSTHROUGH})
            echo "1";;
        ${SCENARIO_FILTER})
            echo "2";;
        ${SCENARIO_PATTERNS})
            echo "3";;
    esac
}

remove_siddhi_app() {
    rm -f ${SIDDHI_APP_DEPLOYMENT_DIR}/TCP_Benchmark.siddhi
    echo "siddhi app removed from the worker."
}

start_server() {
    echo "starting wso2 stream processor.."
    export JAVA_HOME=/opt/jdk/jdk1.8.0_121
    cd ${PRODUCT_HOME}/bin
    sh worker.sh start
}

shutdown_server() {
    echo "shutting down wso2 stream processor.."
    sh worker.sh stop
}

run_tcp_client_with_persistance_disabled() {
    cd ${CLIENT_DIR}
    echo "Executing tcp client"
    java -jar performance-tcp-client-5-jar-with-dependencies.jar localhost 9892 false
}

run_tcp_client_with_persistance_enabled() {
    cd ${CLIENT_DIR}
    echo "Executing tcp client"
    java -jar performance-tcp-client-5-jar-with-dependencies.jar localhost 9892 true
}

execute_test_persistence_disabled() {
    start_server
    wait_until_deploy
    run_tcp_client_with_persistance_disabled
    sleep 5
    shutdown_server
    remove_siddhi_app
}

execute_test_persistence_enabled() {
    start_server
    wait_until_deploy
    run_tcp_client_with_persistance_disabled
    sleep 5
    shutdown_server
    remove_siddhi_app

}
run_passthrough_test() {
    copy_passthrough_siddhiApp
    execute_test_persistence_disabled
}

run_mysql_insert_test() {
    copy_mysql_insert_siddhiApp
    setup_mysql_database
    execute_test_persistence_enabled
}

#main() {
#    setup_wum_updated_pack
#    copy_libs
#    copy_bin_files
#    copy_config_files
#    configure_product
#    start_product
#}

main() {
    copy_siddhiApp
}

main
