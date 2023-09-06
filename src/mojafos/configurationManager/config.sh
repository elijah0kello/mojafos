#!/usr/bin/env bash

########################################################################
# GLOBAL VARS
########################################################################
BASE_DIR=$(pwd)
APPS_DIR="$BASE_DIR/src/mojafos/deployer/apps/"
INFRA_NAMESPACE="infra"
INFRA_RELEASE_NAME="mojafos-infra"
#mojaloop
MOJALOOPBRANCH="main"
MOJALOOPREPO_DIR="mojaloop"
MOJALOOP_NAMESPACE="mojaloop"
MOJALOOP_REPO_LINK="https://github.com/mojaloop/platform-shared-tools.git"
MOJALOOP_LAYER_DIRS=("./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/apps" "./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/ttk" "./src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/crosscut" )
#paymenthubee
PHBRANCH="master"
PHREPO_DIR="ph"
PH_NAMESPACE="paymenthub"
PH_RELEASE_NAME="moja-ph"
PH_VALUES_FILE="$BASE_DIR/src/mojafos/deployer/ph_values.yaml"
PH_REPO_LINK="https://github.com/openMF/ph-ee-env-labs.git"

#fineract
FIN_NAMESPACE="fineract"
FIN_BRANCH="master"
FIN_REPO_LINK="https://github.com/fynarfin/fineract-env.git"
FIN_REPO_DIR="fineract"
FIN_NAMESPACE="fineract"
FIN_RELEASE_NAME="fineract"
FIN_VALUES_FILE="$BASE_DIR/src/mojafos/deployer/fin_values.yaml"

########################################################################
# FUNCTIONS FOR CONFIGURATION MANAGEMENT
########################################################################
function configureMojaloop() {
  echo "${BLUE}Configuring Mojaloop Manifests ${RESET}"
}

function configurePH() {
  local ph_chart_dir=$1
  echo -e "${BLUE} Configuring Payment Hub ${RESET}"

  cd $ph_chart_dir || exit 1

  # Check if make is installed
  if ! command -v make &> /dev/null; then
      echo "make is not installed. Installing make..."
      sudo apt update
      sudo apt install -y make
      echo "make has been installed."
  else
      echo "make is installed. Proceeding to configure"
  fi
  # create secrets for paymenthub
  cd es-secret || exit 1
  make secrets
  cd ..
  cd kibana-secret || exit 1
  make secrets

  # check if the configuration was successful
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Configuration of Paymenthub Successful${RESET}"
  else
    echo -e "${RED}Configuration of Paymenthub Failed${RESET}"
    exit 1
  fi
}

function configureFineract(){
  echo -e "${BLUE}Configuring fineract ${RESET}"
}