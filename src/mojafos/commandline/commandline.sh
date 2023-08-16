#!/bin/bash

source ./src/mojafos/environmentSetup/environmentSetup.sh

function welcome {
  echo -e "███    ███  ██████       ██  █████  ███████  ██████  ███████ "
  echo -e "████  ████ ██    ██      ██ ██   ██ ██      ██    ██ ██      "
  echo -e "██ ████ ██ ██    ██      ██ ███████ █████   ██    ██ ███████ "
  echo -e "██  ██  ██ ██    ██ ██   ██ ██   ██ ██      ██    ██      ██ "
  echo -e "██      ██  ██████   █████  ██   ██ ██       ██████  ███████ "
  echo -e "                                                              "
  echo -e "                                                              "
}

function getoptions {
  local mode_opt

  while getopts "m:" opt; do
    case $opt in
      m)
        mode_opt="$OPTARG"
        ;;
      \?)
        echo "Usage: $0 -m <mode>"
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument."
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


###########################################################################
# MAIN
###########################################################################
function main {
  welcome 
  getoptions "$@"
  echo "Setting up kubernetes and other deployment utilities for Mojaloop, PaymentHub EE and Apache Fineract"
  if [ $mode == "deploy" ]; then
    envSetupMain -m install -k k3s -v 1.26
  elif [ $mode == "cleanup" ]; then
    envSetupMain -m delete -k k3s -v 1.26
  else
    showUsage
  fi
}

###########################################################################
# CALL TO MAIN
###########################################################################
main "$@"