# Red Hat Openshift Multi Clusters Connection through Submariner

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

```$bash
./oc get route -n open-cluster-management multicloud-console -o jsonpath='{.spec.host}'
```

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

## Validate the Submariner Installation

The following procedure includes a set of steps in order to validate each Openshift cluster with Submariner installed.

- List Submariner CRDs

```$bash
./oc get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                                    2022-01-13T16:46:31Z
clusterglobalegressips.submariner.io                                     2022-01-13T16:47:06Z
clusters.submariner.io                                                   2022-01-11T07:54:35Z
endpoints.submariner.io                                                  2022-01-11T07:54:35Z
gateways.submariner.io                                                   2022-01-11T07:54:35Z
globalegressips.submariner.io                                            2022-01-13T16:47:06Z
globalingressips.submariner.io                                           2022-01-13T16:47:06Z
servicediscoveries.submariner.io                                         2022-01-13T16:46:57Z
serviceexports.multicluster.x-k8s.io                                     2022-01-13T16:46:57Z
serviceimports.lighthouse.submariner.io                                  2022-01-14T08:21:43Z
serviceimports.multicluster.x-k8s.io                                     2022-01-11T07:54:35Z
submarinerconfigs.submarineraddon.open-cluster-management.io             2022-01-11T07:53:30Z
submariners.submariner.io                                                2022-01-13T16:46:33Z
```

- Check Openshift hosts dedicated to route Submariner connections

```$bash
./oc  get node --selector=submariner.io/gateway=true -o wide                                               NAME                                       STATUS   ROLES    AGE   VERSION           INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-64-27.us-east-2.compute.internal   Ready    worker   16h   v1.22.3+e790d7f   10.0.64.27    3.143.220.115   Red Hat Enterprise Linux CoreOS 49.84.202201042103-0 (Ootpa)   4.18.0-305.30.1.el8_4.x86_64   cri-o://1.22.1-10.rhaos4.9.gitf1d2c6e.el8
```

- Check Submariner gateway configuration
```$bash
./oc -n submariner-operator describe Gateway
...
Status:
  Connections:
    Endpoint:
      Backend:  libreswan
      backend_config:
        Natt - Discovery - Port:  4490
        Preferred - Server:       false
        Udp - Port:               4500
      cable_name:                 submariner-cable-local-cluster-10-0-64-27
      cluster_id:                 local-cluster
      Health Check IP:            10.128.4.1
      Hostname:                   ip-10-0-64-27
      nat_enabled:                true
      private_ip:                 10.0.64.27
      public_ip:                  3.143.220.115
      Subnets:
        172.30.0.0/16
        10.128.0.0/14
    Latency RTT:
      Average:       56.889875ms
      Last:          56.205435ms
      Max:           62.625688ms
      Min:           54.994115ms
      Std Dev:       861.987µs
    Status:          connected
    Status Message:
    Using IP:        3.143.220.115
    Using NAT:       true
  Ha Status:         active
  Local Endpoint:
    Backend:  libreswan
    backend_config:
      Natt - Discovery - Port:  4490
      Preferred - Server:       false
      Udp - Port:               4500
    cable_name:                 submariner-cable-cluster2-172-25-96-95
    cluster_id:                 cluster2
    Health Check IP:            172.22.2.1
    Hostname:                   ip-172-25-96-95
    nat_enabled:                true
    private_ip:                 172.25.96.95
    public_ip:                  35.87.194.32
    Subnets:
      172.26.0.0/16
      172.20.0.0/14
...
```

- Check Submariner clusters

```$bash
oc -n submariner-operator get clusters.submariner.io
NAME            AGE
cluster1       16h
cluster2   16h
```

- Check Openshift CoreDNS configuration modified by Submariner

```$bash
./oc -n openshift-dns get cm dns-default -o yaml
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.194.126
        errors
        bufsize 512
    }
...
```

- Review Submariner service that support DNS queries

```$bash
./oc -n submariner-operator get service | grep 172.30.194.126
...
submariner-lighthouse-coredns           ClusterIP   172.30.194.126   <none>        53/UDP              16h
```

- Review exported services

```$bash
./oc  get -n submariner-operator serviceimport
NAME                             TYPE           IP                   AGE
back-golang-jump-app-cluster2   ClusterSetIP   ["172.26.241.220"]   16h
```

NOTE: The following command has to be executed in the cluster that exposes the application service

```$bash
./oc describe -n jump-app serviceexport back-golang
...
Name:         back-golang
Namespace:    jump-app
Labels:       <none>
Annotations:  <none>
API Version:  multicluster.x-k8s.io/v1alpha1
Kind:         ServiceExport
Metadata:
  Creation Timestamp:  2022-01-13T17:09:00Z
  Generation:          1
  Resource Version:    352391
  UID:                 af664765-363b-4707-bcd9-6c365b560291
Status:
  Conditions:
    Last Transition Time:  2022-01-13T17:09:00Z
    Message:               Awaiting sync of the ServiceImport to the broker
    Reason:                AwaitingSync
    Status:                False
    Type:                  Valid
    Last Transition Time:  2022-01-13T17:09:00Z
    Message:               Service was successfully synced to the broker
    Reason:
    Status:                True
    Type:                  Valid
Events:                    <none>
```

- Retrieve internal service IP 

```$bash
## Deploy dnsutils POD
./oc new-project dnstest
./oc apply -f test/dnsutils.yaml -n dnstest

## Perform a DNS query in order to discover the service gateway
./oc -n dnstest exec dnsutils dig back-golang.jump-app.svc.clusterset.local

; <<>> DiG 9.9.5-9+deb8u19-Debian <<>> back-golang.jump-app.svc.clusterset.local
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35732
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;back-golang.jump-app.svc.clusterset.local. IN A

;; ANSWER SECTION:
back-golang.jump-app.svc.clusterset.local. 5 IN	A 172.26.241.220

;; Query time: 3 msec
;; SERVER: 172.30.0.10#53(172.30.0.10)
;; WHEN: Fri Jan 14 11:45:46 UTC 2022
;; MSG SIZE  rcvd: 127
```

NOTE: The following command has to be executed in the cluster that exposes the application service

```$bash
./oc get svc -A | grep 172.26.241.220
...
jump-app    back-golang    ClusterIP      172.26.241.220   <none>     8442/TCP   18h
```

## Author

Asier Cidon @Red Hat
