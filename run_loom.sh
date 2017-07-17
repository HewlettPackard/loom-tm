#!/bin/sh
#*******************************************************************************
# (c) Copyright 2017 Hewlett Packard Enterprise Development LP Licensed under the Apache License,
# Version 2.0 (the "License"); you may not use this file except in compliance with the License. You
# may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#*******************************************************************************
LOOM_TM_PATH=/usr/share/loom-tm
cd /usr/share/loom-tm
java -Djavax.net.ssl.trustStore=${LOOM_TM_PATH}/truststore \
	-Dloom-server.path=${LOOM_TM_PATH}/target/loom-server.war \
    -Dweaver.path=${LOOM_TM_PATH}/target/weaver.war \
    -Ded.path=${LOOM_TM_PATH}/target/tm-ed.war \
    -Ddeployment.properties=${LOOM_TM_PATH}/deployment-deb.properties \
    -Dlog4j.configuration=file:${LOOM_TM_PATH}/log4j-deb.properties \
    -jar ${LOOM_TM_PATH}/target/jetty-runner.jar \
     --config ${LOOM_TM_PATH}/jetty.xml ${LOOM_TM_PATH}/md-context.xml ${LOOM_TM_PATH}/ed-context.xml ${LOOM_TM_PATH}/loom-context.xml
