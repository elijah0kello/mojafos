#!/usr/bin/env bash
########################################################################
# GLOBAL VARS
########################################################################
INFRA_NAMESPACE="infra"
INFRA_RELEASE_NAME="mojafos-infra"
MOJALOOPBRANCH="main"
MOJALOOPREPO_DIR="mojaloop-utils"

function installInfraCRDS() {
  printf "Installing CRDs for elastic search \n"
  kubectl create -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml
  kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml -n "$INFRA_NAMESPACE"
}

function deploy_helm_chart() {
  # Check if Helm is installed
  if ! command -v helm &>/dev/null; then
    echo "Helm is not installed. Please install Helm first."
    exit 1
  fi

  # Check if the chart directory exists
  chart_dir="$1"
  if [ ! -d "$chart_dir" ]; then
    echo "Chart directory '$chart_dir' does not exist."
    exit 1
  fi

  # Enter the chart directory
  cd "$chart_dir" || exit 1

  # Determine whether to install or upgrade the chart
  if helm list -n "$INFRA_NAMESPACE" | grep -q "$INFRA_RELEASE_NAME"; then
    echo "Upgrading Helm chart..."
    helm upgrade --install "$INFRA_RELEASE_NAME" . -n "$INFRA_NAMESPACE"
  else
    echo "Installing Helm chart..."
    helm install "$INFRA_RELEASE_NAME" . -n "$INFRA_NAMESPACE"
  fi

  # Exit the chart directory
  cd - || exit 1
}

########################################################################
# Deploy Helm charts to a specified namespace
########################################################################
function deployInfraCharts() {
  # Specify the path to the JSON file
  local json_file="./src/mojafos/deployer/infrahelm.json"

  # Check if jq is installed
  if ! command -v jq &>/dev/null; then
    echo "jq is not installed. Please install it to run this script."
    exit 1
  fi

  # Check if the JSON file exists
  if [ ! -f "$json_file" ]; then
    echo "JSON file not found: $json_file"
    exit 1
  fi

  # Read and iterate through the JSON file
  while IFS= read -r chart_data; do
    repo=$(echo "$chart_data" | jq -r '.repo_link')
    repo_name=$(echo "$chart_data" | jq -r '.repo_name')
    release_name=$(echo "$chart_data" | jq -r '.release_name')
    chart=$(echo "$chart_data" | jq -r '.chart_name')
    values=$(echo "$chart_data" | jq -r '.values')
    enabled=$(echo "$chart_data" | jq -r '.enabled')

    echo "Repo: $repo"
    echo "Chart: $chart"
    echo "Release: $release_name"
    echo "Repo Name: $repo_name"
    echo "Values:"
    echo "$values"
    echo "Enabled: $enabled"

    if [ "$enabled" == true ]; then
      echo "Deploying chart from $repo_name to namespace $INFRA_NAMESPACE..."

      helm repo add "$repo_name" "$repo"  # Add the remote repository (replace "repo-name" with a suitable name)
      helm repo update

      # Install the charts from the repository into the specified namespace
      if [ -z "$values" ]; then
          echo "No Values present"
          helm install "$release_name" "$repo_name/$chart" --namespace "$INFRA_NAMESPACE"
      else
          echo "Values present"
          helm install "$release_name" "$repo_name/$chart" --set "$values" --namespace "$INFRA_NAMESPACE"
      fi

      if [ $? -eq 0 ]; then
          echo "Charts from $repo deployed successfully."
      else
          echo "Failed to deploy charts from $repo."
      fi

      echo "----------------------"
    else
      echo "Chart $chart not enabled. Skipping..."
    fi
  done < <(jq -c '.[]' "$json_file")
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

function testInfra() {
  echo "Testing Infra"
}

########################################################################
# Deploy Infrastructure to infra namespace
########################################################################
function deployInfrastructure () {
    printf "Deploying infrastructure \n"
#    deployInfraCharts
    deploy_helm_chart "./src/mojafos/deployer/helm/infra"
}

function cloneMojaloopRepo() {
  echo -e "Cloning Mojaloop repository"
  git clone --branch $MOJALOOPBRANCH https://github.com/mojaloop/platform-shared-tools.git $MOJALOOPREPO_DIR > /dev/null 2>&1
}

function deployMojaloop(){
  echo "Deploying Mojaloop vNext application manifests"

}

function deployApps(){
  echo -e "${BLUE} Deploying Apps ...${RESET}"
  echo -e "${BLUE} Deploying Mojaloop ... ${RESET}"
  deployMojaloop
}
