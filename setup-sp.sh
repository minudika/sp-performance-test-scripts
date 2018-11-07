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

readonly SCENARIO=$1
readonly WINDOW_SIZE=$2
readonly NODE_ID=$3
readonly INSTALLATION_DIR=$4
readonly PRODUCT_NAME="wso2sp"
readonly PRODUCT_VERSION=$5

readonly ARTIFACT_DIR="${INSTALLATION_DIR}/artifacts"
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"
readonly PRODUCT_DOWNLOAD_URL="https://github.com/wso2/product-sp/releases/download/v${PRODUCT_VERSION}/wso2sp-4.3.0.zip"
readonly JAVA_HOME_PATH="/usr/lib/jvm/java-8-oracle"
readonly PRODUCT_ZIP_PATH="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}.zip"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"
readonly SP_LIB_DIR="${PRODUCT_HOME}/lib"
readonly SP_CONF_DIR="${PRODUCT_HOME}/conf/worker"


readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"
readonly SIDDHI_APP_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/artifacts"
readonly LIB_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/libs"
readonly CONF_DIR="${INSTALLATION_DIR}/${ARTIFACT_REPO_NAME}/conf"

readonly MYSQL_USERNAME=root
readonly MYSQL_PASSWORD=root

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

readonly SERVER_ID1=1;
readonly SERVER_ID2=2;

readonly DEPLOYMENT_YAML=deployment.yaml
readonly PERFORMANCE_EXTENSION_JAR_NAME="siddhi-execution-performance-4.3.0.jar"
readonly MYSQL_DRIVER_LIB_NAME="mysql-connector-java-5.1.42-bin.jar"

clone_artifacts() {
    mkdir -p ${INSTALLATION_DIR}
    cd ${INSTALLATION_DIR}
    echo "Cloning performance test artifacts"
    git clone ${SIDDHI_APP_REPO_URL}
}

unzip_procuct_pack() {
    echo "Unzipping ${PRODUCT_ZIP_PATH}.."
    unzip ${PRODUCT_ZIP_PATH} -d ${INSTALLATION_DIR}
}

copy_conf() {
    cd ${CONF_DIR}
    if [[ ${NODE_ID} == ${SERVER_ID1} ]]; then
        echo "Copying ${NODE_ID}/deployment.yaml to ${NODE_ID}.."
        cp ${NODE_ID}/${DEPLOYMENT_YAML} ${SP_CONF_DIR}
    elif [[ ${NODE_ID} == ${SERVER_ID2} ]]; then
        echo "Copying ${NODE_ID}/deployment.yaml to ${NODE_ID}.."
        cp ${NODE_ID}/${DEPLOYMENT_YAML} ${SP_CONF_DIR}
    else
        echo "Provided node id : ${NODE_ID} is invalid!"
    fi
}

setup_mysql_database() {
    echo "Setting up mysql database"
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
    setup_mysql_database
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
    cp ${PERFORMANCE_EXTENSION_JAR_NAME} ${SP_LIB_DIR}
    cp ${MYSQL_DRIVER_LIB_NAME} ${SP_LIB_DIR}
}

remove_siddhi_app() {
    rm -f ${SIDDHI_APP_DEPLOYMENT_DIR}/TCP_Benchmark.siddhi
    echo "Siddhi app removed from the worker."
}

start_server() {
    echo "Starting wso2 stream processor.."
    export JAVA_HOME=${JAVA_HOME_PATH}
    cd ${PRODUCT_HOME}/bin
    sh worker.sh start
}


main() {
    clone_artifacts
    unzip_procuct_pack
    copy_conf
    copy_siddhiApp
    copy_libs
    start_server
}

main
