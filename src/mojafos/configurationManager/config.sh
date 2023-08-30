#!/usr/bin/env bash

########################################################################
# GLOBAL VARS
########################################################################
APPS_DIR="./src/mojafos/deployer/apps/"
INFRA_NAMESPACE="infra"
INFRA_RELEASE_NAME="mojafos-infra"
#mojaloop
MOJALOOPBRANCH="main"
MOJALOOPREPO_DIR="mojaloop"
MOJALOOP_NAMESPACE="mojaloop"
MOJALOOP_REPO_LINK="https://github.com/mojaloop/platform-shared-tools.git"
MOJALOOP_LAYER_DIRS=("./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/apps" "./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/ttk" "./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/crosscut" )
#paymenthubee
PHBRANCH="main"
PHREPO_DIR="ph"
PH_NAMESPACE="ph"
PH_REPO_LINK="https://github.com/mojaloop/platform-shared-tools.git"


########################################################################
# FUNCTIONS FOR CONFIGURATION MANAGEMENT
########################################################################
function configureMojaloop() {
  echo "${BLUE}Configuring Mojaloop Manifests ${RESET}"
}