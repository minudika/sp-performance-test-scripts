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


readonly NODE_ID_1=1
readonly REMOTE_IP1=192.168.57.248
readonly REMOTE_USERNAME1=ubuntu
readonly NODE_ID_2=2
readonly REMOTE_IP2=192.168.57.25
readonly REMOTE_USERNAME2=ubuntu
readonly REMOTE_CLIENT_IP=192.168.57.95
readonly REMOTE_CLIENT_USERNAME=ubuntu

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
readonly DISTRIBUTION_PATH_1=${NODE_ID_1}/${DISTRIBUTION_NAME}
readonly DISTRIBUTION_PATH_2=${NODE_ID_2}/${DISTRIBUTION_NAME}

readonly SP_PACK_PATH_1=${DISTRIBUTION_PATH_1}/${PRODUCT_PACK_NAME}
readonly SP_PACK_PATH_2=${DISTRIBUTION_PATH_2}/${PRODUCT_PACK_NAME}



readonly REMOTE_INSTALLATION_PATH=home/ubuntu


readonly MYSQL_USERNAME=root
readonly MYSQL_PASSWORD=root

readonly KEY="/home/minudika/Projects/WSO2/dev/resources/keys/ssh-key"


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

setup_distribution() {
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

    mkdir -p ${DISTRIBUTION_PATH_1}
    mkdir -p ${DISTRIBUTION_PATH_2}
    echo "Unzipping ${PRODUCT_ZIP_NAME} into 1/${DISTRIBUTION_NAME}"
    unzip -q ${PRODUCT_ZIP_NAME} -d 1/${DISTRIBUTION_NAME}
    echo "Unzipping ${PRODUCT_ZIP_NAME} into 2/${DISTRIBUTION_NAME}"
    unzip -q ${PRODUCT_ZIP_NAME} -d 2/${DISTRIBUTION_NAME}

    echo "Copying ${ARTIFACT_REPO_NAME}/conf/1/deployment.yaml into ${SP_PACK_PATH_1}/conf/worker/"
    cp ${ARTIFACT_REPO_NAME}/conf/1/deployment.yaml ${SP_PACK_PATH_1}/conf/worker/
    echo "Copying ${ARTIFACT_REPO_NAME}/libs/* into ${SP_PACK_PATH_1}/lib/"
    cp  ${ARTIFACT_REPO_NAME}/libs/* ${SP_PACK_PATH_1}/lib

    echo "Copying ${ARTIFACT_REPO_NAME}/conf/2/deployment.yaml into ${SP_PACK_PATH_2}/conf/worker/"
    cp ${ARTIFACT_REPO_NAME}/conf/2/deployment.yaml ${SP_PACK_PATH_2}/conf/worker/
    echo "Copying ${ARTIFACT_REPO_NAME}/libs/* into ${SP_PACK_PATH_2}/lib/"
    cp  ${ARTIFACT_REPO_NAME}/libs/* ${SP_PACK_PATH_2}/lib

    cp ${SCRIPT_REPO_NAME}/setup-sp.sh ${DISTRIBUTION_PATH_1}
    cp ${SCRIPT_REPO_NAME}/shutdown-sp.sh ${DISTRIBUTION_PATH_1}
    cp ${SCRIPT_REPO_NAME}/clean.sh ${DISTRIBUTION_PATH_1}

    cp ${SCRIPT_REPO_NAME}/setup-sp.sh ${DISTRIBUTION_PATH_2}
    cp ${SCRIPT_REPO_NAME}/shutdown-sp.sh ${DISTRIBUTION_PATH_2}
    cp ${SCRIPT_REPO_NAME}/clean.sh ${DISTRIBUTION_PATH_2}

    cd ${NODE_ID_1/
    zip -rq ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip ${DISTRIBUTION_NAME}/
    mv ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip ${script_location}
    cd ${script_location}/${NODE_ID_2}
    zip -rq ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip ${DISTRIBUTION_NAME}/
    mv ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip ${script_location}

    echo "Uploading ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip to ${REMOTE_IP1}"
    scp -i ${KEY} ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip ${REMOTE_USERNAME1}@${REMOTE_IP1}:${REMOTE_INSTALLATION_PATH}

    echo "Uploading ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip to ${REMOTE_IP2}"
    scp -i ${KEY} ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip ${REMOTE_USERNAME1}@${REMOTE_IP1}:${REMOTE_INSTALLATION_PATH}
}

execute_client() {
    echo "Executing client.."
    ssh -i ${KEY} ${REMOTE_CLIENT_USERNAME}@${REMOTE_CLIENT_IP} ./client.sh\
      /home/ubuntu 1000 1 1000 900000 1 1000 1 192.168.57.248 9892 ubuntu 2 192.168.57.25 9892 ubuntu\
      /home/ubuntu/keys/ssh-key 4.3.0

}

main() {
    setup_distribution
    execute_client
}

main
