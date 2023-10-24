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

  # Use kubectl to get the resource count in the specified namespace
  resource_count=$(kubectl get pods -n "$namespace" --ignore-not-found=true 2>/dev/null | grep -v "No resources found" | wc -l)

  # Check if the deployment was successful
  if [ $resource_count -gt 0 ]; then
    echo "Helm chart deployed successfully."
  else
    echo -e "${RED}Helm chart deployment failed.${RESET}"
    cleanUp
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

function runFailedSQLStatements(){
  echo "Fxing Operations App MySQL Race condition"
  operationsDeplName=$(kubectl get deploy --no-headers -o custom-columns=":metadata.name" -n $PH_NAMESPACE | grep operations-app)
  kubectl exec -it mysql-0 -n infra -- mysql -h mysql -uroot -pethieTieCh8ahv < src/mojafos/deployer/setup.sql

  if [ $? -eq 0 ];then
    echo "SQL File execution successful"
  else 
    echo "SQL File execution failed"
    exit 1
  fi

  echo "Restarting Deployment for Operations App"
  kubectl rollout restart deploy/$operationsDeplName -n $PH_NAMESPACE

  if [ $? -eq 0 ];then
    echo "Deployment Restart successful"
  else 
    echo "Deployment Restart failed"
    exit 1
  fi
}

#Function to run kong migrations in Kong init container 
function runKongMigrations(){
  echo "Fixing Kong Migrations"
  #StoreKongPods
  kongPods=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $PH_NAMESPACE | grep moja-ph-kong)
  dBcontainerName="wait-for-db"
  for pod in $kongPods; 
  do 
    podName=$(kubectl get pod $pod --no-headers -o custom-columns=":metadata.labels.app" -n $PH_NAMESPACE)
    if [[ "$podName" == "moja-ph-kong" ]]; then 
        initContainerStatus=$(kubectl get pod $pod  --no-headers -o custom-columns=":status.initContainerStatuses[0].ready" -n $PH_NAMESPACE)
      while [[ "$initContainerStatus" != "true" ]]; do
        printf "\rReady State: $initContainerStatus Waiting for status to become true ..."
        initContainerStatus=$(kubectl get pod $pod  --no-headers -o custom-columns=":status.initContainerStatuses[0].ready" -n $PH_NAMESPACE)
        sleep 5
      done
      echo "Status is now true"
      while  kubectl get pod "$podName" -o jsonpath="{:status.initContainersStatuses[1].name}" | grep -q "$dBcontainerName" ; do
        printf "\r Waiting for Init DB container to be created ..."
        sleep 5
      done

      echo && echo $pod
      statusCode=1
      while [ $statusCode -eq 1 ]; do
        printf "\rRunning Migrations ..."
        kubectl exec $pod -c $dBcontainerName -n $PH_NAMESPACE -- kong migrations bootstrap >> /dev/null 2>&1
        statusCode=$?
        if [ $statusCode -eq 0 ]; then
          echo "\nKong Migrations Successful"
        fi
      done
    else
      continue
    fi
  done
}

function postPaymenthubDeploymentScript(){
  #Run migrations in Kong Pod
  runKongMigrations
  # Run failed MySQL statements.
  runFailedSQLStatements
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
  
  for((i=1; i<=2; i++))
  do
    deployHelmChartFromDir "$APPS_DIR$PHREPO_DIR/helm/g2p-sandbox-fynarfin-SIT" "$PH_NAMESPACE" "$PH_RELEASE_NAME" "$PH_VALUES_FILE"
  done 
  postPaymenthubDeploymentScript
}

function deployFineract() {
  echo -e "${BLUE}Deploying Fineract${RESET}"

  cloneRepo "$FIN_BRANCH" "$FIN_REPO_LINK" "$APPS_DIR" "$FIN_REPO_DIR"
  configureFineract

  read -p "How many instances of fineract would you like to deploy? Enter number: " num_instances
  echo -e "Deploying $num_instances instances of fineract"

  if [ $num_instances -eq 0 ];then
    num_instances=2
  fi
  
  # Check if the input is a valid integer
  for ((i=1; i<=num_instances; i++))
  do
    sed -i "s/\([0-9]-\)\?fynams.sandbox.fynarfin.io/$i-fynams.sandbox.fynarfin.io/" "$FIN_VALUES_FILE"
    sed -i "s/\([0-9]-\)\?communityapp.sandbox.fynarfin.io/$i-communityapp.sandbox.fynarfin.io/" "$FIN_VALUES_FILE"
    createNamespace "$FIN_NAMESPACE-$i"
    deployHelmChartFromDir "$APPS_DIR$FIN_REPO_DIR/helm/fineract" "$FIN_NAMESPACE-$i" "$FIN_RELEASE_NAME-$i" "$FIN_VALUES_FILE"
  done
}

function testApps {
  echo "TODO" #TODO Write function to test apps
}

function printEndMessage {
  echo "TODO" #TODO Write function to conclude script.
}

function deployApps {
  echo -e "${BLUE}Deploying Apps ...${RESET}"
  deployMojaloop
  deployPaymentHubEE
  deployFineract
  testApps
  printEndMessage
}
