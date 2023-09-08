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
MOJALOOP_LAYER_DIRS=("$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/apps" "$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/ttk" "$BASE_DIR/src/mojafos/deployer/apps/mojaloop/packages/deployment/k8s/crosscut" )
MOJALOOP_VALUES_FILE="$BASE_DIR/src/mojafos/configurationManager/mojaloop_values.json"
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
function replaceValuesInYaml() {
  local yaml_file="$1"
  local old_value="$2"
  local new_value="$3"

  # Check if sed is available, if not, exit with an error message
  if ! command -v sed &>/dev/null; then
      echo "Error: 'sed' is not available. Please make sure it's installed on your system."
      return 1
  fi

  # Print debugging information
  echo "Updating YAML file: $yaml_file"
  echo "Old value: $old_value"
  echo "New value: $new_value"

  # Use sed to update the YAML file with the new value
  if sed -i "s/$old_value/$new_value/" "$yaml_file"; then
      echo "Value updated successfully."
      return 0
  else
      echo "Error updating the value."
      return 1
  fi
}

function renameOffToYaml() {
  local folder="$1"
  local previous_dir="$PWD"  # Save the current working directory

  # Check if the folder exists
  if [ ! -d "$folder" ]; then
    echo "Error: The specified folder does not exist."
    return 1
  fi

  # Navigate to the folder
  cd "$folder" || return 1

  # Rename all .off files to .yaml
  for file in *.off; do
    if [ -e "$file" ]; then
      new_name="${file%.off}.yaml"  # Remove .off and add .yaml
      mv "$file" "$new_name"
      echo "Renamed: $file -> $new_name"
    fi
  done

  # Return to the previous working directory
  cd "$previous_dir" || return 1

  echo "Renaming completed."
}

function configureMojaloop() {
  echo -e "${BLUE}Configuring Mojaloop Manifests ${RESET}"
  local json_file=$MOJALOOP_VALUES_FILE

  # Check if jq is installed, if not, exit with an error message
  if ! command -v jq &>/dev/null; then
      echo "Error: 'jq' is not installed. Please install it (https://stedolan.github.io/jq/) and make sure it's in your PATH."
      return 1
  fi

  # Check if the JSON file exists
  if [ ! -f "$json_file" ]; then
      echo "Error: JSON file '$json_file' does not exist."
      return 1
  fi

  # Loop over JSON objects in the file and call the process_json_object function
  jq -c '.[]' "$json_file" | while read -r json_object; do
      local file_name
      local old_value
      local new_value

      # Extract attributes from the JSON object
      file_name=$(echo "$json_object" | jq -r '.file_name')
      old_value=$(echo "$json_object" | jq -r '.old_value')
      new_value=$(echo "$json_object" | jq -r ".new_value")

      # Call the  function with the extracted attributes
      replaceValuesInYaml "$(pwd)/$file_name" "$old_value" "$new_value"
  done

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Mojaloop Manifests edited successfully${RESET}"
  else
    echo -e "${RED}Mojaloop Manifests were not edited successfully${RESET}"
  fi
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