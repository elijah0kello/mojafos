#!/usr/bin/env bash

source ./src/mojafos/configurationManager/config.sh

function deployHelmChart() {
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

function createNamespace () {
  local namespace=$1
  printf "Creating namespace $namespace \n"
  # Check if the namespace already exists
  if kubectl get namespace "$namespace" > /dev/null 2>&1; then
      echo -e "${RED}Namespace $namespace already exists.${RESET}"
      exit 1
  fi

  # Create the namespace
  kubectl create namespace "$namespace"
  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Namespace $namespace created successfully. ${RESET}"
  else
      echo "Failed to create namespace $namespace."
  fi
}

function deployInfrastructure () {
  printf "Deploying infrastructure \n"
  createNamespace $INFRA_NAMESPACE
  deployHelmChart "./src/mojafos/deployer/helm/infra"
}

function cloneRepo() {
  if [ "$#" -ne 4 ]; then
      echo "Usage: clone_repo <branch> <repo_link> <target_directory> <cloned_directory_name>"
      return 1
  fi

  # Store the current working directory
  original_dir="$(pwd)"

  branch="$1"
  repo_link="$2"
  target_directory="$3"
  cloned_directory_name="$4"

  # Check if the target directory exists; if not, create it.
  if [ ! -d "$target_directory" ]; then
      mkdir -p "$target_directory"
  fi

  # Change to the target directory.
  cd "$target_directory" || return 1

  # Clone the repository with the specified branch into the specified directory.
  if [ -d "$cloned_directory_name" ]; then
    echo -e "${YELLOW}$cloned_directory_name Repo exists deleting and re-cloning ${RESET}"
    rm -rf "$cloned_directory_name"
    git clone -b "$branch" "$repo_link" "$cloned_directory_name"
  else
    git clone -b "$branch" "$repo_link" "$cloned_directory_name"
  fi

  if [ $? -eq 0 ]; then
      echo "Repository cloned successfully."
  else
      echo "Failed to clone the repository."
  fi

  # Change back to the original directory
  cd "$original_dir" || return 1
}

function applyKubeManifests() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: applyKubeManifests <directory> <namespace>"
        return 1
    fi

    local directory="$1"
    local namespace="$2"

    # Check if the directory exists.
    if [ ! -d "$directory" ]; then
        echo "Directory '$directory' not found."
        return 1
    fi

    # Use 'kubectl apply' to apply manifests in the specified directory.
    kubectl apply -f "$directory" -n "$namespace"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Kubernetes manifests applied successfully.${RESET}"
    else
        echo -e "${RED}Failed to apply Kubernetes manifests.${RESET}"
    fi
}

function deployMojaloop(){
  echo "Deploying Mojaloop vNext application manifests"
  createNamespace "$MOJALOOP_NAMESPACE"
  cloneRepo "$MOJALOOPBRANCH" "$MOJALOOP_REPO_LINK" "$APPS_DIR" "$MOJALOOPREPO_DIR"

  for index in "${!MOJALOOP_LAYER_DIRS[@]}"; do
    folder="${MOJALOOP_LAYER_DIRS[index]}"
    echo "Deploying files in $folder"
    applyKubeManifests "$folder" "$MOJALOOP_NAMESPACE"
  done
}

function deployPaymentHubEE() {
  echo "Deploying PaymentHub EE"
  createNamespace ""
}

function deployFineract() {
  echo "Deploying Fineract"
}

function deployApps(){
  echo -e "${BLUE} Deploying Apps ...${RESET}"
  deployMojaloop
}
