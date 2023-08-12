#!/bin/bash

function check_ubuntu_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

function install_required_tools() {
    local tools=("curl" "kubectl" "k3s" "helm" "python3")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        echo "All required tools are already installed."
    else
        echo "Installing missing tools: ${missing_tools[*]}"
        sudo apt update
        sudo apt install -y "${missing_tools[@]}"
    fi
}

function create_kubernetes_cluster() {
    if check_ubuntu_os; then
        install_required_tools

        read -p "Would you like to use a remote Kubernetes cluster or a local one? (remote/local): " cluster_type

        if [[ "$cluster_type" == "remote" ]]; then
            echo "Verifying connection to the remote Kubernetes cluster..."
            kubectl get pods >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                echo "Successfully connected to the remote Kubernetes cluster."
            else
                echo "Failed to connect to the remote Kubernetes cluster."
                return 1
            fi
        elif [[ "$cluster_type" == "local" ]]; then
            echo "Creating a local Kubernetes cluster using k3s..."
            curl -sfL https://get.k3s.io | sh -
            if [[ $? -eq 0 ]]; then
                echo "Local Kubernetes cluster created successfully."
            else
                echo "Failed to create the local Kubernetes cluster."
                return 1
            fi
        else
            echo "Invalid choice. Please choose either 'remote' or 'local'."
            return 1
        fi
    else
        echo "This script is intended to run on Ubuntu only."
        return 1
    fi
}
