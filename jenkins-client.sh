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
#readonly PRODUCT_DOWNLOAD_URL=${1}
#readonly CLIENT_HOME=${2}
#readonly NODE_ID_1=${3}
#readonly REMOTE_SERVER_IP1=${4}
#readonly PORT1=${18}
#readonly REMOTE_SERVER_USERNAME1=${4}
#readonly NODE_ID_2=${20}
#readonly REMOTE_SERVER_IP2=${5}
#readonly PORT2=${22}
#readonly REMOTE_SERVER_USERNAME2=${6}
#readonly REMOTE_CLIENT_IP=${7}
#readonly REMOTE_CLIENT_USERNAME=${8}
#readonly REMOTE_INSTALLATION_PATH=${9}
#readonly BATCH_SIZE=${10}
#readonly THREAD_COUNT=${11}
#readonly INTERVAL=${12} #Time between batches
#readonly TEST_DURATION=${13}
#readonly SCENARIO=${14}
#readonly WINDOW_SIZE=${15}
#readonly JENKINS_SSH_KEY=${16}
#readonly CLIENT_SSH_LEY=${17}
#readonly SERVER_INSTALLATION_DIR=${18}
#readonly CLIENT_INSTALLATION_DIR=${19}
#readonly PRODUCT_VERSION=${20}


readonly PRODUCT_NAME=wso2sp
readonly PRODUCT_VERSION=4.3.0
readonly PRODUCT_ZIP_FILE_PATH=${PRODUCT_HOME}.zip
readonly JAVA_HOME_PATH="/usr/lib/jvm/java-8-oracle"
readonly PRODUCT_ZIP_FILE_PATH=${PRODUCT_HOME}.zip
readonly PRODUCT_DOWNLOAD_URL="https://github.com/wso2/product-sp/releases/download/v${PRODUCT_VERSION}/wso2sp-4.3.0.zip"

# databases
readonly WSO2_UM_DB="WSO2_UM_DB"
readonly WSO2_REG_DB="WSO2_REG_DB"
readonly WSO2_ANALYTICS_EVENT_STORE="WSO2_ANALYTICS_EVENT_STORE_DB"
readonly WSO2_ANALYTICS_PROCESSED_DATA_STORE="WSO2_ANALYTICS_PROCESSED_DATA_STORE_DB"
readonly WSO2_AM_STATS_DB="WSO2_AM_STATS_DB"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"
readonly SP_CONF_DIR=${PRODUCT_NAME}-${PRODUCT_VERSION}/conf/worker/
readonly SP_LIB_DIR="${PRODUCT_HOME}/lib"

readonly ARTIFACT_REPO_NAME="sp-performance-test-resources"
readonly ARTIFACT_REPO_URL="https://github.com/minudika/${ARTIFACT_REPO_NAME}"


readonly SCRIPT_REPO_URL="git@github.com:minudika/sp-performance-test-scripts.git"
readonly SCRIPT_REPO_NAME="sp-performance-test-scripts"

readonly DISTRIBUTION_NAME="distribution"
readonly PRODUCT_ZIP_NAME="${PRODUCT_NAME}-${PRODUCT_VERSION}.zip"
readonly PRODUCT_PACK_NAME="${PRODUCT_NAME}-${PRODUCT_VERSION}"


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

download_product() {
    if [ ! -f ${PRODUCT_ZIP_FILE_PATH} ]; then
        echo "Downloading ${PRODUCT_NAME}-${PRODUCT_VERSION}.zip.."
        wget ${PRODUCT_DOWNLOAD_URL}
    fi
}

build_distribution() {
    script_location="`dirname \"$0\"`"              # relative
    script_location="`( cd \"$script_location\" && pwd )`"  # absolutized and normalized
    if [ -z "$script_location" ] ; then
        exit 1  # fail
    fi
    cd ${script_location}


    echo "Cloning ${SCRIPT_REPO_URL} into ${script_locatoin}.."
    git clone ${SCRIPT_REPO_URL}
    echo "Cloning ${ARTIFACT_REPO_URL} into ${script_locatoin}.."
    git clone ${ARTIFACT_REPO_URL}

    echo "Unzipping ${PRODUCT_ZIP_NAME} into 1/"
    unzip -q ${PRODUCT_ZIP_NAME} -d distribution-1/
    echo "Unzipping ${PRODUCT_ZIP_NAME} into 2/"
    unzip -q ${PRODUCT_ZIP_NAME} -d distribution-2/

    echo "Copying ${ARTIFACT_REPO_NAME}/conf/1/deployment.yaml into distribution-1/${PRODUCT_PACK_NAME}/conf/worker/"
    cp ${ARTIFACT_REPO_NAME}/conf/1/deployment.yaml distribution-1/${PRODUCT_PACK_NAME}/conf/worker/
    echo "Copying ${ARTIFACT_REPO_NAME}/libs/* into distribution-1/${PRODUCT_PACK_NAME}/lib/"
    cp  ${ARTIFACT_REPO_NAME}/libs/* distribution-1/${PRODUCT_PACK_NAME}/lib

    echo "Copying ${ARTIFACT_REPO_NAME}/conf/2/deployment.yaml into 2/${PRODUCT_PACK_NAME}/conf/worker/"
    cp ${ARTIFACT_REPO_NAME}/conf/2/deployment.yaml distribution-2/${PRODUCT_PACK_NAME}
    echo "Copying ${ARTIFACT_REPO_NAME}/libs/* into distribution-2/${PRODUCT_PACK_NAME}/lib/"
    cp  ${ARTIFACT_REPO_NAME}/libs/* distribution-2/${PRODUCT_PACK_NAME}/lib

    cp ${SCRIPT_REPO_NAME}/setup-sp.sh distribution-1/
    cp ${SCRIPT_REPO_NAME}/clean.sh distribution-1/

    cp ${SCRIPT_REPO_NAME}/setup-sp.sh distribution-2/
    cp ${SCRIPT_REPO_NAME}/clean.sh distribution-2/

    zip -rq distribution-1.zip distribution-1/
    zip -rq distribution-2.zip distribution-2/


}

upload_product() {
    echo "Uploading ${PRODUCT_NAME}-${PRODUCT_VERSION}.zip to ${REMOTE_SERVER_IP1}"
    scp -i ${KEY} ${PRODUCT_ZIP_FILE_PATH} ${REMOTE_SERVER_USERNAME1}@${REMOTE_SERVER_IP1}:${REMOTE_INSTALLATION_PATH}

    echo "Uploading ${PRODUCT_NAME}-${PRODUCT_VERSION}.zip to ${REMOTE_SERVER_IP12}"
    scp -i ${KEY} ${PRODUCT_ZIP_FILE_PATH} ${REMOTE_SERVER_USERNAME1}@${REMOTE_SERVER_IP2}:${REMOTE_INSTALLATION_PATH}
}

execute_client() {
    echo "Executing client.."
    ssh -i ${JENKINS_SSH_KEY} ${REMOTE_CLIENT_USERNAME}@${REMOTE_CLIENT_IP} ./setup-sp.sh
}

main() {
    build_distribution
}

main
