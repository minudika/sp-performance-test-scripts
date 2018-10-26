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
#set -o verbose

readonly PRODUCT_NAME=wso2sp
readonly PRODUCT_VERSION=4.3.0
readonly INSTALLATION_DIR=/home/ubuntu
readonly ARTIFACT_DIR="${INSTALLATION_DIR}/artifacts"
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"
readonly JAVA_HOME_PATH="/usr/lib/jvm/java-8-oracle"

# databases
readonly WSO2_UM_DB="WSO2_UM_DB"
readonly WSO2_REG_DB="WSO2_REG_DB"
readonly WSO2_ANALYTICS_EVENT_STORE="WSO2_ANALYTICS_EVENT_STORE_DB"
readonly WSO2_ANALYTICS_PROCESSED_DATA_STORE="WSO2_ANALYTICS_PROCESSED_DATA_STORE_DB"
readonly WSO2_AM_STATS_DB="WSO2_AM_STATS_DB"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"
readonly SP_LIB_DIR="${PRODUCT_HOME}/lib"


readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"
readonly SIDDHI_APP_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/artifacts"
readonly CLIENT_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/clients"
readonly LIB_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/libs"


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

copy_mssql_insert_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/MSSQL/Insert/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_mssql_update_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/MSSQL/Update/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_oracle_insert_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/Oracle/Insert/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
}

copy_oracle_update_siddhiApp() {
    cd ${SIDDHI_APP_DIR}
    cp "Persistence/Oracle/Update/TCP_Benchmark.siddhi" ${SIDDHI_APP_DEPLOYMENT_DIR}
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
            copy_passthrough_siddhiApp;;
        ${SCENARIO_FILTER})
            copy_Filter_siddhiApp;;
        ${SCENARIO_PATTERNS})
            copy_patterns_siddhiApp;;
        ${SCENARIO_PARTITIONS})
            copy_partitions_siddhiApp;;
        ${SCENARIO_WINDOW_LARGE})
            copy_large_window_siddhiApp;;
        ${SCENARIO_WINDOW_SMALL})
            copy_small_window_siddhiApp;;
        ${SCENARIO_PERSISTENCE_MYSQL_INSERT})
            copy_mysql_insert_siddhiApp;;
        ${SCENARIO_PERSISTENCE_MYSQL_UPDATE})
            copy_mysql_update_siddhiApp;;
        ${SCENARIO_PERSISTENCE_MSSQL_INSERT})
            copy_mssql_insert_siddhiApp;;
        ${SCENARIO_PERSISTENCE_MSSQL_UPDATE})
            copy_mssql_update_siddhiApp;;
        ${SCENARIO_PERSISTENCE_ORACLE_INSERT})
            copy_oracle_insert_siddhiApp;;
        ${SCENARIO_PERSISTENCE_ORACLE_UPDATE})
            copy_oracle_update_siddhiApp;;
    esac
}

copy_libs() {
    cd ${LIB_DIR}
    cp "siddhi-execution-performance-4.3.0.jar" ${SP_LIB_DIR}
}

remove_siddhi_app() {
    rm -f ${SIDDHI_APP_DEPLOYMENT_DIR}/TCP_Benchmark.siddhi
    echo "siddhi app removed from the worker."
}

start_server() {
    echo "starting wso2 stream processor.."
    export JAVA_HOME=${JAVA_HOME_PATH}
    cd ${PRODUCT_HOME}/bin
    sh worker.sh start
}


main() {
    clone_artifacts
    copy_siddhiApp
    copy_libs
    start_server
}

main
