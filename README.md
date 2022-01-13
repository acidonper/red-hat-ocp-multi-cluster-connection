# Openshift Cluster Interconnection via Submariner

This repository tries to collect the required information to install a couple of Openshift clusters in AWS and connect them through Submariner.

The idea is to make use of Red Hat Advanced Cluster Management in order to support Submariner installation/configuration process.

## Introduction

In order to deploy and interconnect a set of Openshift cluster, there are some tools that facilitate the clusters bootstrap and make possible to configure the final architecture.

Please review the following section to get more information about ed Hat Advanced Cluster Management anb Submariner.

### Red Hat Advanced Cluster Management

[Red Hat Advanced Cluster Management](https://www.redhat.com/en/technologies/management/advanced-cluster-management) for Kubernetes controls clusters and applications from a single console, with built-in security policies. Extend the value of Red Hat OpenShift® by deploying apps, managing multiple clusters, and enforcing policies across multiple clusters at scale. 

### Submariner

[Submariner](https://submariner.io/) connects multiple Kubernetes clusters in a way that is secure and performant. Submariner flattens the networks between the connected clusters, and enables IP reachability between Pods and Services. Submariner also provides, via Lighthouse, service discovery capabilities.

## Prerequisites

- An AWS account with specific permissions and a set of resources (*Please visit [link](https://docs.openshift.com/container-platform/4.9/installing/installing_aws/installing-aws-account.html#installing-aws-account) for more information about creating an AWS account with required permission*)
- A Pull Secret downloaded from the Red Hat OpenShift Cluster Manager site (file named **pull-secret.txt**)
- A RSA public key (file named **id_rsa.pub**)

## Setting OCP Clusters Up

The first step is to create both Openshift clusters using the following procedures:

- Install Cluster RHACM

```$bash
## Define variables
export CLUSTER_VERSION=4.9
export CLUSTER_FOLDER=/tmp/ocp4_install_clusterrhacm
export CLUSTER_NAME=clusterrhacm
export CLUSTER_REGION=us-west-1
export CLUSTER_DOMAIN=acidonpe.com
export CLUSTER_POD_NET=172.20.0.0/14
export CLUSTER_SRV_NET=172.26.0.0/16
export CLUSTER_HOSTS_NET=172.25.0.0/16
export PULL_SECRET=$(cat pull-secret.txt)
export SSH_KEY=$(cat id_rsa.pub)

## Install Cluster RHACM
sh 00-install-ocp-cluster.sh
```

- Install Cluster 1

```$bash
## Define variables
export CLUSTER_VERSION=4.9
export CLUSTER_FOLDER=/tmp/ocp4_install_cluster1
export CLUSTER_NAME=cluster1
export CLUSTER_REGION=us-east-1
export CLUSTER_DOMAIN=acidonpe.com
export CLUSTER_POD_NET=172.20.0.0/14
export CLUSTER_SRV_NET=172.26.0.0/16
export CLUSTER_HOSTS_NET=172.25.0.0/16
export PULL_SECRET=$(cat pull-secret.txt)
export SSH_KEY=$(cat id_rsa.pub)

## Install Cluster 1
sh 00-install-ocp-cluster.sh
```

- Install Cluster 2

```$bash
## Define variables
export CLUSTER_VERSION=4.9
export CLUSTER_FOLDER=/tmp/ocp4_install_cluster2
export CLUSTER_NAME=cluster2
export CLUSTER_REGION=us-east-2
export CLUSTER_DOMAIN=acidonpe.com
export CLUSTER_POD_NET=10.128.0.0/14
export CLUSTER_SRV_NET=10.1.0.0/16
export CLUSTER_HOSTS_NET=10.0.0.0/16
export PULL_SECRET=$(cat pull-secret.txt)
export SSH_KEY=$(cat id_rsa.pub)

## Install Cluster 2
sh 00-install-ocp-cluster.sh
```

## Setting Red Hat Advanced Cluster Management Solution Up

Once Openshift clusters are installed, it is time to install RHACM Operator and deploy the solution:

```$bash
./oc login -u kubeadmin -p xxxx https://api.clusterrhacm.acidonpe.com:6443
sh 01-install-rhacm.sh
```

NOTE: Please find kubeadmin credentials in /tmp/ocp4_install_clusterrhacm/.openshift_install.log

Once the RHACM solution is installed and ready, it is time to visit the RHACM console and import both cluster1 and cluster2 managed clusters:

oc get route -n open-cluster-management multicloud-console -o jsonpath='{.spec.host}'

NOTE: Please follow [Import OCP Cluster to RHACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/clusters/managing-your-clusters#importing-an-existing-cluster-with-the-console) for importing both clusters

## Setting Submariner Architecture Up

### Preparing both clusters from RHACM

Once RHACM Hub and both managed clusters are installed and properly configured, it is time to deploy Submariner. In order to do that, it is required to follow the next steps:

```$bash
./oc login -u kubeadmin -p xxxx https://api.clusterrhacm.acidonpe.com:6443

export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
sh 02-install-submariner.sh
```

NOTE: Please visit [Install and Configure Submariner via RHACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/services/services-overview#deploying-submariner-mcaddon-api) for more information about the precess

### Install the test solution

In order to test the Submariner deployment in both clusters, it is time to deploy an application in a specific cluster and export this service to the rest of the clusters via Submariner.

Follow the next steps to test the final solution:

```$bash
./oc login -u kubeadmin -p xxxx https://api.cluster1.acidonpe.com:6443
sh 03-testing-final-env

./oc login -u kubeadmin -p xxxx https://api.cluster2.acidonpe.com:6443
POD=$(./oc get pod -n submariner-operator -l app=submariner-addon -o jsonpath='{.items[0].metadata.name}')
./oc -n submariner-operator exec ${POD} curl back-golang.jump-app.svc.clusterset.local:8442
...
 / - Greetings from Golang!
```

## Author

Asier Cidon @Red Hat
