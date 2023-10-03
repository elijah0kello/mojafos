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
sudo ./run.sh -m deploy
```

After running this command, it will run a few checks and then it will ask you whether you want to setup a kubernetes cluster locally or you want to connect to a remote one that is already configured using kubectl
```
Would you like to use a remote Kubernetes cluster or a local one? (remote/local): 
```
Choose your preferred option depending on where you want to run the kubernetes cluster to run the applications.
Enter remote to use a remote cluster and enter local to let the tool create a local cluster using k3s.
>Currently the tool is only tested on local kubernetes deployments but work is being done to test it on remote kubernetes clusters

After entering in your preferred option allow the script to run and deploy the softwares. After  the script has successfully executed it will print the following output

```
NAME: fineract
LAST DEPLOYED: Sat Sep 23 13:34:37 2023
NAMESPACE: fineract
STATUS: deployed
REVISION: 1
TEST SUITE: None
Helm chart installed 
Helm chart deployed successfully.
/home/azureuser/elijah/mojafos2
Port forwarding terminated.
```

>The script may throw warnings but just ignore them. 
