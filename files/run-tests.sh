#!/bin/bash
#
# Copyright (C) 2016 Red Hat, Inc.
#
# Licensed under the GNU General Public License, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         https://www.gnu.org/licenses/gpl.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

. /opt/rh/rh-maven33/enable

check_variables() {
    [ -z "$KUBERNETES_MASTER" ] && {
        echo "Missing variable KUBERNETES_MASTER. Exiting."
        exit 1
    }
    echo "Openshift URL: $KUBERNETES_MASTER"

    [ -n "$KUBERNETES_AUTH_TOKEN" ] && {
        echo "OpenShift token provided, using it instead of username and password"
    } || {
        OPENSHIFT_USERNAME=${OPENSHIFT_USERNAME:-"test"}
        OPENSHIFT_PASSWORD=${OPENSHIFT_PASSWORD:-"test"}
        echo "Using Openshift credentials: $OPENSHIFT_USERNAME/********"
    }
    echo

    ARQUILLIAN_CUBE_URL=${ARQUILLIAN_CUBE_URL:-"https://github.com/arquillian/arquillian-cube.git"}
    ARQUILLIAN_CUBE_BRANCH=${ARQUILLIAN_CUBE_BRANCH:-"master"}
    echo "Arquillian Cube URL: $ARQUILLIAN_CUBE_URL"
    echo "Arquillian Cube branch: $ARQUILLIAN_CUBE_BRANCH"
    echo

    CE_ARQ_URL=${CE_ARQ_URL:-"https://github.com/jboss-openshift/ce-arq.git"}
    CE_ARQ_BRANCH=${CE_ARQ_BRANCH:-"master"}
    echo "ce-arq URL: $CE_ARQ_URL"
    echo "ce-arq branch: $CE_ARQ_BRANCH"
    echo

    CE_TESTSUITE_URL=${CE_TESTSUITE_URL:-"https://github.com/jboss-openshift/ce-testsuite.git"}
    CE_TESTSUITE_BRANCH=${CE_TESTSUITE_BRANCH:-"master"}
    echo "ce-testsuite URL: $CE_TESTSUITE_URL"
    echo "ce-testsuite branch: $CE_TESTSUITE_BRANCH"
    echo

    echo "Additional maven args: $MAVEN_ARGS"
    echo
}

configure_maven() {
    [ -n "$MAVEN_SETTINGS_URL" ] && {
        echo "Using $MAVEN_SETTINGS_URL for maven settings"
        curl -k -s "$MAVEN_SETTINGS_URL" -o /home/test/.m2/settings.xml
    } || {
        echo "MAVEN_SETTINGS_URL variable not provided. Not using any maven settings."
    }

    echo
}

install_arq_cube() {
    echo "Installing arquillian-cube..."
    (git clone --depth=1 -b "$ARQUILLIAN_CUBE_BRANCH" "$ARQUILLIAN_CUBE_URL" && \
        cd arquillian-cube && \
        mvn -nsu clean install -DskipTests && \
        cd .. \
    ) || exit 1

    echo
}

install_ce_arq() {
    echo "Installing ce-arq..."
    (git clone --depth=1 -b "$CE_ARQ_BRANCH" "$CE_ARQ_URL" && \
        cd ce-arq && \
        mvn -nsu clean install -DskipTests && \
        cd .. \
    ) || exit 1

    echo
}

install_ce_testsuite() {
    echo "Installing ce-testsuite..."
    (git clone --depth=1 -b "$CE_TESTSUITE_BRANCH" "$CE_TESTSUITE_URL" && \
        cd ce-testsuite && \
        mvn -nsu clean install -DskipTests && \
        cd .. \
    ) || exit 1

    echo
}

login_openshift() {
    echo "Logging into OpenShift..."
    local args
    [ -n "$KUBERNETES_AUTH_TOKEN" ] && {
        args="--token=$KUBERNETES_AUTH_TOKEN"
    } || {
        args="-u $OPENSHIFT_USERNAME -p $OPENSHIFT_PASSWORD"
    }

    oc --insecure-skip-tls-verify login "$KUBERNETES_MASTER" $args || exit 1
    export KUBERNETES_AUTH_TOKEN=$(oc whoami -t)

    echo
}

run_tests() {
    # Unset some variables that might conflict with java openshift client
    unset OPENSHIFT_URL MASTER_URL

    echo "Running tests..."
    (cd ce-testsuite && \
     mvn -nsu clean test $MAVEN_ARGS
    ) || exit 1

    echo
}

check_variables
configure_maven
install_arq_cube
install_ce_arq
install_ce_testsuite
login_openshift
run_tests

echo
echo "Done."
echo
