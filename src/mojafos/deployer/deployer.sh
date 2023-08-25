#!/usr/bin/env bash
########################################################################
# GLOBAL VARS
########################################################################
INFRA_NAMESPACE="infra"
INFRA_REPO_NAMES=("elastic")
INFRA_CHART_NAMES=("eck-stack")
INFRA_RELEASE_NAMES=("moja-elasticsearch" )
INFRA_REPO_ARRAY=("https://helm.elastic.co")
INFRA_CHART_VALUES=("resources.requests.cpu=1m,resources.requests.memory=128M,antiAffinity=soft" "")

function installInfraCRDS() {
  printf "Installing CRDs for elastic search \n"
  kubectl create -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml -q
  kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml -n "$INFRA_NAMESPACE" -q
}

########################################################################
# Deploy Helm charts to a specified namespace
########################################################################
function deployInfraCharts() {
    local NAMESPACE="$1"
    shift
    local number=${#INFRA_REPO_NAMES[@]}

    # Iterate through the array and deploy each Helm chart
    for ((i=0; i <number; i++)); do
      echo "Deploying charts from $REPO to namespace $NAMESPACE..."

      helm repo add "${INFRA_REPO_NAMES[i]}" "${INFRA_REPO_ARRAY[i]}"  # Add the remote repository (replace "repo-name" with a suitable name)
      helm repo update

      # Install the charts from the repository into the specified namespace
      helm install "${INFRA_RELEASE_NAMES[i]}" "${INFRA_REPO_NAMES[i]}/${INFRA_CHART_NAMES[i]}" --set "${INFRA_CHART_VALUES[i]}" --namespace "$NAMESPACE"

      if [ $? -eq 0 ]; then
          echo "Charts from ${INFRA_REPO_ARRAY[i]} deployed successfully."
      else
          echo "Failed to deploy charts from ${INFRA_REPO_ARRAY[i]}."
      fi
    done
}

########################################################################
# Create Infrastructure namespace
########################################################################
function createInfrastructureNamespace () {
  printf "Creating Infrastructure namespace called infra \n"
  # Check if the namespace already exists
  if kubectl get namespace "$INFRA_NAMESPACE" > /dev/null 2>&1; then
      echo -e "${RED}Namespace $INFRA_NAMESPACE already exists.${RESET}"
      exit 1
  fi

  # Create the namespace
  kubectl create namespace "$INFRA_NAMESPACE"
  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Namespace $INFRA_NAMESPACE created successfully. ${RESET}"
  else
      echo "Failed to create namespace $INFRA_NAMESPACE."
  fi
}

########################################################################
# Deploy Infrastructure to infra namespace
########################################################################
function deployInfrastructure () {
    printf "Deploying infrastructure \n"
    deployInfraCharts $INFRA_NAMESPACE
}
