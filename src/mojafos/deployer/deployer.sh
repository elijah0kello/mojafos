#!/usr/bin/env bash


function createInfrastructureNamespace () {
  printf "Creating Infrastructure namespace called infra \n"
  # Set the namespace name
  NAMESPACE_NAME="infra"

  # Check if the namespace already exists
  if kubectl get namespace "$NAMESPACE_NAME" > /dev/null 2>&1; then
      echo -e "${RED}Namespace $NAMESPACE_NAME already exists.${RESET}"
      exit 1
  fi

  # Create the namespace
  kubectl create namespace "$NAMESPACE_NAME"
  if [ $? -eq 0 ]; then
      echo -e "${GREEN}Namespace $NAMESPACE_NAME created successfully. ${RESET}"
  else
      echo "Failed to create namespace $NAMESPACE_NAME."
  fi
}

function deployInfrastructure () {
  printf "Deploying Infrastructure into infrastructure namespace"

}
