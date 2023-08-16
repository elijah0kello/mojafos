# A Deployable Package for Mifos/Fineract, Payment Hub EE, and Mojaloop (Mojafos)

## Introduction

The deployable package is intended to simplify and automate the deployment process of three software applications, namely Mojaloop, PaymentHub, and Fineract, onto a Kubernetes cluster. This package aims to streamline the deployment process, reduce manual errors, and enable someone to demo how these softwares can work together. 

## Purpose

The purpose of this document is to provide a comprehensive overview of the deployable package, detailing its functionalities, architecture, and usage.

## Scope

The Deployable Package will perform the following tasks:

- Accept user input to specify the Kubernetes cluster's configuration or create a new kubernetes cluster. 
- Retrieve the necessary deployment helm charts for the software applications.
- Edit each software application helm chart in order for the software to function correctly in the kubernetes cluster.
- Create Kubernetes resources for each software application in their respective namespace.
- Configure environment variables and secrets as needed for the software applications.
- Provide status updates on the deployment process.
- Deploy infrastructure in a single namespace
- Check the health of each deployed application to see if it is ready to serve requests.

## Usage 

`deploy` : Set up the kubernetes environment, deploy infrastructure and deploy the applications (mojaloop, paymenthub, and fineract).

`health-check-interval <seconds>` : Set the interval between health checks during deployment.

`check-infra` : Check the health status of the deployed infrastructure components.

`check-apps` : Check the health status of the deployed applications (mojaloop, paymenthub, fineract).

Options:
`--<app-name>` : Provide the name of the application to check. e.g paymenthub, fineract or mojaloop

`cleanup` : Remove all deployed resources and clean up the environment.

`show-config`: Display the current configuration settings of the tool.

`help` or `-h`: Display the help message with information about available commands and options.