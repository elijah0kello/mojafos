#!/usr/bin/env bash

source ./src/mojafos/environmentSetup/environmentSetup.sh
source ./src/mojafos/deployer/deployer.sh

# Text color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

function welcome {
  echo -e "${YELLOW}"
  echo -e "███    ███  ██████       ██  █████  ███████  ██████  ███████ "
  echo -e "████  ████ ██    ██      ██ ██   ██ ██      ██    ██ ██      "
  echo -e "██ ████ ██ ██    ██      ██ ███████ █████   ██    ██ ███████ "
  echo -e "██  ██  ██ ██    ██ ██   ██ ██   ██ ██      ██    ██      ██ "
  echo -e "██      ██  ██████   █████  ██   ██ ██       ██████  ███████ "
  echo -e "                                                              "
  echo -e "                                                              ${RESET}"
}

function showUsage {
  echo -e "Show usage for Mojafos"
}

function getoptions {
  local mode_opt

  while getopts "m:n:u:hH" OPTION ; do
    case "${OPTION}" in
            m)	    mode_opt="${OPTARG}"
            ;;
            k)      k8s_distro="${OPTARG}"
            ;;
            v)	    k8s_user_version="${OPTARG}"
            ;;
            u)      k8s_user="${OPTARG}"
            ;;
            h|H)	showUsage
                    exit 0
            ;;
            *)	echo  "unknown option"
                    showUsage
                    exit 1
            ;;
        esac
    done

  if [ -z "$mode_opt" ]; then
    echo "Error: Mode argument is required."
    exit 1
  fi

  mode="$mode_opt"
}

# this function is called when Ctrl-C is sent
function cleanUp ()
{
    # perform cleanup here
    echo -e "${RED}Performing graceful clean up${RESET}"

    mode="cleanup"
    echo "Doing cleanup" 
    envSetupMain "$mode" "k3s" "1.26"

    # exit shell script with error code 2
    # if omitted, shell script will continue execution
    exit 2
}

function trapCtrlc {
  echo
  echo -e "${RED}Ctrl-C caught...performing clean up${RESET}"
  cleanUp
}

# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trapCtrlc" 2

###########################################################################
# MAIN
###########################################################################
function main {
  welcome 
  getoptions "$@"
  if [ $mode == "deploy" ]; then
    echo -e "${BLUE}Setting up kubernetes and other deployment utilities for Mojaloop, PaymentHub EE and Apache Fineract${RESET}"
    envSetupMain "$mode" "k3s" "1.26"
    deployInfrastructure
    deployApps
  elif [ $mode == "cleanup" ]; then
    echo -e "${BLUE}Cleaning up all traces of Mojafos${RESET}"
    envSetupMain "$mode" "k3s" "1.26"
  else
    showUsage
  fi
}

###########################################################################
# CALL TO MAIN
###########################################################################
main "$@"