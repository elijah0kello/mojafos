# A Deployable Package for Mifos/Fineract, Payment Hub EE, and Mojaloop (Mojafos)

## Introduction

The deployable package is intended to simplify and automate the deployment process of three software applications, namely Mojaloop, PaymentHub, and Fineract, onto a Kubernetes cluster. This package aims to streamline the deployment process, reduce manual errors, and enable someone to demo how these softwares can work together. 


## Pre-requisites
Make sure you have the following before you go through this guide.
- You should be running Ubuntu 22.04 LTS on the machine where you are running this script
- 32GB of RAM
- 30GB+ free space in your home directory

# Quick Start

## Clone the repository
To use Mojafos, you need to clone the repository to be able to run the software scripts.
Clone the repository into a directory of your choice.
After cloning the repository,  you need to change the directory into the cloned repository.
``` 
git clone https://github.com/elijah0kello/mojafos.git
```

Inside the directory run the following command to execute the script.

```
sudo ./run.sh -u $USER -m deploy
```

> NOTE: The deployment made by this script is meant for demo purposes and not for production

After running this command, it will run a few checks and then it will ask you whether you want to setup a kubernetes cluster locally or you want to connect to a remote one that is already configured using kubectl
```
Would you like to use a remote Kubernetes cluster or a local one? (remote/local): 
```
Choose your preferred option depending on where you want to run the kubernetes cluster to run the applications.
Enter remote to use a remote cluster and enter local to let the tool create a local cluster using k3s.
>Currently the tool is only tested on local kubernetes deployments but work is being done to test it on remote kubernetes clusters

After entering in your preferred option allow the script to run and deploy the softwares.

At some point in the script's execution, it will ask you for the number of fineract instances you would like to deploy.

```
How many instances of fineract would you like to deploy? Enter number:
```

Enter the number of instances you would like to deploy and press enter.

After  the script has successfully executed it will print the following output

```
========================================================================
Thank you for installing Mojaloop, Paymenthub and Fineract using Mojafos
========================================================================


TESTING
sudo ./run -u $USER -m test ml #For testing mojaloop
sudo ./run -u $USER -m test ph #For testing payment hub
sudo ./run -u $USER -m test fin #For testing fineract



CHECK DEPLOYMENTS USING kubectl
kubectl get pods -n mojaloop #For testing mojaloop
kubectl get pods -n paymenthub #For testing paymenthub
kubectl get pods -n fineract-n #For testing fineract. n is a number of a fineract instance


Copyright © 2023 The Mifos Initiative
```

## WHAT HAS NOT YET BEEN DONE
- Clear logging and providing option for verbosity
- Proper function return codes to support proper exception handling
- Support to allow the user specify the number of fineract instances to deploy
- Stabilise paymenthub deployment 
- Add a note in the logs to state that this is not a production grade deployment of the softwares
- Show usage message
