#!/usr/bin/env bash

source ./src/mojafos/configurationManager/config.sh

function deployHelmChartFromDir() {
  # Check if Helm is installed
  if ! command -v helm &>/dev/null; then
    echo "Helm is not installed. Please install Helm first."
    exit 1
  fi

  # Check if the chart directory exists
  local chart_dir="$1"
  local namespace="$2"
  local release_name="$3"
  if [ ! -d "$chart_dir" ]; then
    echo "Chart directory '$chart_dir' does not exist."
    exit 1
  fi

  # Check if a values file has been provided
  values_file="$4"

  # Enter the chart directory
  cd "$chart_dir" || exit 1

  # Run helm dependency update to fetch dependencies
  echo "Updating Helm chart dependencies..."
  helm dependency update >> /dev/null 2>&1
  echo -e "${GREEN}Helm chart updated ${RESET}"

  # Run helm dependency build
  echo "Building Helm chart dependencies..."
  helm dependency build . >> /dev/null 2>&1
  echo -e "${GREEN}Helm chart dependencies built ${RESET}"

  # Determine whether to install or upgrade the chart also check whether to apply a values file
  if [ -n "$values_file" ]; then
    if helm list -n "$namespace" | grep -q "$release_name"; then
      echo "Upgrading Helm chart..."
      helm upgrade --install "$release_name" . -n "$namespace" -f "$values_file"
      echo -e "${GREEN}Helm chart upgraded ${RESET}"
    else
      echo "Installing Helm chart..."
      helm install "$release_name" . -n "$namespace" -f "$values_file"
      echo -e "${GREEN}Helm chart installed ${RESET}"
    fi
  else
    if helm list -n "$namespace" | grep -q "$release_name"; then
      echo "Upgrading Helm chart..."
      helm upgrade --install "$release_name" . -n "$namespace"
      echo -e "${GREEN}Helm chart upgraded ${RESET}"
    else
      echo "Installing Helm chart..."
      helm install "$release_name" . -n "$namespace"
      echo -e "${GREEN}Helm chart installed ${RESET}"
    fi
  fi

  # Check if the deployment was successful
  if [ $? -eq 0 ]; then
    echo "Helm chart deployed successfully."
  else
    echo "Helm chart deployment failed."
    return 1
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
  deployHelmChartFromDir "./src/mojafos/deployer/helm/infra" "$INFRA_NAMESPACE" "$INFRA_RELEASE_NAME"
}

function cloneRepo() {
  if [ "$#" -ne 4 ]; then
      echo "Usage: cloneRepo <branch> <repo_link> <target_directory> <cloned_directory_name>"
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

# Function to perform port forwarding
function performPortForward() {
    kubectl -n "$INFRA_NAMESPACE" port-forward service/"$MYSQL_SERVICE_NAME" "$LOCAL_PORT":"$MYSQL_SERVICE_PORT" &
    PORT_FORWARD_PID=$!
    trap portForwardCleanup EXIT

    # Wait for the port to become accessible
    local wait_seconds=0
    until [ $wait_seconds -ge "$MAX_WAIT_SECONDS" ] || nc -z -v -w1 127.0.0.1 "$LOCAL_PORT"; do
        sleep 2
        wait_seconds=$((wait_seconds + 2))
    done

    if [ $wait_seconds -ge "$MAX_WAIT_SECONDS" ]; then
        echo "Port forwarding did not become accessible within the specified time."
        exit 1
    fi
}

# Function to clean up the port forward
function portForwardCleanup() {
    kill $PORT_FORWARD_PID
    wait $PORT_FORWARD_PID 2>/dev/null
    echo "Port forwarding terminated."
}

# Function to execute SQL statements
function executeSqlStatementsFromFile() {
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$LOCAL_PORT" < "$SQL_FILE"
    if [ $? -eq 0 ]; then
        echo "SQL statements executed successfully from '$SQL_FILE'."
    else
        echo "Error executing SQL statements from '$SQL_FILE'."
    fi
}

# Function to restart a deployment in a specific namespace
function restartDeployment() {
    local deployment_name="$1"
    local namespace="$2"

    if [ -z "$deployment_name" ] || [ -z "$namespace" ]; then
        echo "Usage: restart_deployment <deployment_name> <namespace>"
        return 1
    fi

    # Check if the deployment exists in the given namespace
    if ! kubectl get deployment "$deployment_name" -n "$namespace" &>/dev/null; then
        echo "Deployment '$deployment_name' not found in namespace '$namespace'."
        return 1
    fi

    # Use 'kubectl rollout restart' to restart the deployment
    kubectl rollout restart deployment "$deployment_name" -n "$namespace"

    echo "Restarting deployment '$deployment_name' in namespace '$namespace'."
}

function postPaymenthubDeploymentScript(){
   echo "Fixing MySQL Race Condition"
   performPortForward
   executeSqlStatementsFromFile
   restartDeployment "ph-ee-operations-app" "$PH_NAMESPACE"
}

function deployMojaloop() {
  echo "Deploying Mojaloop vNext application manifests"
  createNamespace "$MOJALOOP_NAMESPACE"
  cloneRepo "$MOJALOOPBRANCH" "$MOJALOOP_REPO_LINK" "$APPS_DIR" "$MOJALOOPREPO_DIR"
  renameOffToYaml "${MOJALOOP_LAYER_DIRS[0]}"
  configureMojaloop

  for index in "${!MOJALOOP_LAYER_DIRS[@]}"; do
    folder="${MOJALOOP_LAYER_DIRS[index]}"
    echo "Deploying files in $folder"
    applyKubeManifests "$folder" "$MOJALOOP_NAMESPACE"
    if [ "$index" -eq 0 ]; then
      echo -e "${BLUE}Waiting for Mojaloop cross cutting concerns to come up${RESET}"
      sleep 10
      echo -e "Proceeding ..."
    fi
  done
}

function deployPaymentHubEE() {
  echo "Deploying PaymentHub EE"
  createNamespace "$PH_NAMESPACE"
  cloneRepo "$PHBRANCH" "$PH_REPO_LINK" "$APPS_DIR" "$PHREPO_DIR"
  configurePH "$APPS_DIR$PHREPO_DIR/helm"
  deployHelmChartFromDir "$APPS_DIR$PHREPO_DIR/helm/g2p-sandbox-fynarfin-SIT" "$PH_NAMESPACE" "$PH_RELEASE_NAME" "$PH_VALUES_FILE"


  # Use kubectl to get the resource count in the specified namespace
  resource_count=$(kubectl get all -n "$PH_NAMESPACE" --ignore-not-found=true 2>/dev/null | grep -v "No resources found" | wc -l)

  if [ "$resource_count" -lt 0 ];then
    deployHelmChartFromDir "$APPS_DIR$PHREPO_DIR/helm/g2p-sandbox-fynarfin-SIT" "$PH_NAMESPACE" "$PH_RELEASE_NAME" "$PH_VALUES_FILE"
  fi
  # postPaymenthubDeploymentScript
}

function deployFineract() {
  echo -e "${BLUE}Deploying Fineract${RESET}"

  cloneRepo "$FIN_BRANCH" "$FIN_REPO_LINK" "$APPS_DIR" "$FIN_REPO_DIR"
  configureFineract

  read -p "How many instances of fineract would you like to deploy? Enter number: " num_instances
  echo -e "Deploying $num_instances instances of fineract"

  # Check if the input is a valid integer
  for ((i=1; i<=num_instances; i++))
  do
    sed -i "s/\([0-9]-\)\?fynams.sandbox.fynarfin.io/$i-fynams.sandbox.fynarfin.io/" "$FIN_VALUES_FILE"
    sed -i "s/\([0-9]-\)\?communityapp.sandbox.fynarfin.io/$i-communityapp.sandbox.fynarfin.io/" "$FIN_VALUES_FILE"
    createNamespace "$FIN_NAMESPACE-$i"
    deployHelmChartFromDir "$APPS_DIR$FIN_REPO_DIR/helm/fineract" "$FIN_NAMESPACE-$i" "$FIN_RELEASE_NAME-$i" "$FIN_VALUES_FILE"
  done
}

function deployApps(){
  echo -e "${BLUE}Deploying Apps ...${RESET}"
  deployMojaloop
  deployPaymentHubEE
  deployFineract
}
