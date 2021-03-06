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
readonly PRODUCT_VERSION=4.3.0
declare INSTALLATION_DIR="`dirname \"$0\"`"              # relative
INSTALLATION_DIR="`( cd \"$INSTALLATION_DIR\" && pwd )`"

readonly ARTIFACT_DIR="${INSTALLATION_DIR}/artifacts"
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"
readonly JAVA_HOME_PATH="/usr/lib/jvm/java-8-oracle"

readonly SIDDHI_APP_DEPLOYMENT_DIR="${PRODUCT_HOME}/wso2/worker/deployment/siddhi-files"
readonly SP_LIB_DIR="${PRODUCT_HOME}/lib"

readonly SIDDHI_APP_REPO_NAME="sp-performance-test-resources"
readonly SIDDHI_APP_REPO_URL="https://github.com/minudika/${SIDDHI_APP_REPO_NAME}"
readonly SIDDHI_APP_DIR="${INSTALLATION_DIR}/${SIDDHI_APP_REPO_NAME}/artifacts"
readonly CLIENT_DIR="${INSTALLATION_DIR}/${SIDDHI_APP_REPO_NAME}/clients"
readonly LIB_DIR="${INSTALLATION_DIR}/${SIDDHI_APP_REPO_NAME}/libs"



clean() {
    rm -rf ${PRODUCT_HOME}/wso2/worker/performance-results
    rm -f ${SIDDHI_APP_DEPLOYMENT_DIR}/TCP_Benchmark.siddhi
    echo "Siddhi app and performance results removed from the worker."
}

shutdown_server() {
    echo "Shutting down wso2 stream processor.."
    export JAVA_HOME=${JAVA_HOME_PATH}
    cd ${PRODUCT_HOME}/bin
    sh worker.sh stop
}

main() {
    shutdown_server
}

main
