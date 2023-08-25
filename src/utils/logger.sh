#!/usr/bin/env bash

function logWithLevel() {
  local logLevel=$1
  shift
  local logMessage=$@
  case "$logLevel" in
    "debug")
        echo -e "${BLUE}DEBUG${RESET} $logMessage "
        ;;
    "error")
        echo -e "${RED}ERROR${RESET} $logMessage "
        ;;
    *) # Default case
        echo "$logMessage"
        ;;
  esac
}

function logWithVerboseCheck() {
  local verbose=$1
  local level=$2
  shift && shift
  local message=$@

  if [ -n "$verbose" ]; then
    logWithLevel $level $message
  fi
}

