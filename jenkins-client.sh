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

readonly PRODUCT_NAME=wso2sp
readonly JAVA_HOME_PATH="/usr/lib/jvm/java-8-oracle"
readonly PRODUCT_DOWNLOAD_URL="https://github.com/wso2/product-sp/releases/download/v${PRODUCT_VERSION}/wso2sp-4.3.0.zip"


args=("$@")
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
readonly REMOTE_CLIENT_IP=${args[14]}
readonly REMOTE_CLIENT_USERNAME=${args[15]}
readonly CLIENT_KEY=${args[16]}
readonly PRODUCT_VERSION=${args[17]}
readonly SCENARIOS=${args[18]}

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

readonly REMOTE_INSTALLATION_PATH=/home/ubuntu
readonly RESULTS_ZIP_NAME="results.zip"

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
    script_location="`dirname \"$0\"`"
    script_location="`( cd \"$script_location\" && pwd )`"
    if [ -z "$script_location" ] ; then
        exit 1
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

    cd ${NODE_ID_1}/
    echo "Creating ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip.."
    zip -rq ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip ${DISTRIBUTION_NAME}/
    mv ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip ${script_location}

    cd ${script_location}/${NODE_ID_2}
    echo "Creating ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip.."
    zip -rq ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip ${DISTRIBUTION_NAME}/
    mv ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip ${script_location}

    cd ${script_location}

    echo "Uploading ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip to ${REMOTE_IP1}"
    sudo scp -i ${KEY} ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip \
    ${REMOTE_USERNAME1}@${REMOTE_IP1}:${REMOTE_INSTALLATION_PATH}

    echo "Extracting ${DISTRIBUTION_NAME} in ${REMOTE_IP1}:${REMOTE_INSTALLATION_PATH}"
    sudo ssh -i ${KEY} ${REMOTE_USERNAME1}@${REMOTE_IP1}  "unzip -q ${DISTRIBUTION_NAME}-${NODE_ID_1}.zip"

    echo "Uploading ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip to ${REMOTE_IP2}"
    sudo scp -i ${KEY} ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip \
    ${REMOTE_USERNAME2}@${REMOTE_IP2}:${REMOTE_INSTALLATION_PATH}

    echo "Extracting ${DISTRIBUTION_NAME} in ${REMOTE_IP2}:${REMOTE_INSTALLATION_PATH}"
    sudo ssh -i ${KEY} ${REMOTE_USERNAME2}@${REMOTE_IP2}  "unzip -q ${DISTRIBUTION_NAME}-${NODE_ID_2}.zip"

    cd ${script_location}

    echo "Uploading client.sh to ${REMOTE_CLIENT_IP}"
    sudo scp -i ${KEY} ${SCRIPT_REPO_NAME}/client.sh\
     ${REMOTE_CLIENT_USERNAME}@${REMOTE_CLIENT_IP}:${REMOTE_INSTALLATION_PATH}

    sudo scp -i ${KEY} ${REMOTE_CLIENT_USERNAME}@${REMOTE_CLIENT_IP}:${REMOTE_INSTALLATION_PATH}/${RESULTS_ZIP_NAME}\
    ${script_location}
}

execute_client() {
    echo "Executing client.."
      sudo ssh -i ${KEY} ${REMOTE_CLIENT_USERNAME}@${REMOTE_CLIENT_IP} ./client.sh\
      ${CLIENT_DIR} ${BATCH_SIZE} ${THREAD_COUNT} ${INTERVAL} ${TEST_DURATION} ${WINDOW_SIZE} ${NODE_ID_1}\
      ${REMOTE_IP1} ${PORT1} ${REMOTE_USERNAME1} ${NODE_ID_2} ${REMOTE_IP2} ${PORT2} ${REMOTE_USERNAME2} ${CLIENT_KEY}\
      ${PRODUCT_VERSION} ${SCENARIOS}
}

main() {
    setup_distribution
    execute_client
}

main
