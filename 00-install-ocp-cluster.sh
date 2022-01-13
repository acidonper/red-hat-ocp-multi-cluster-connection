#!/bin/bash
##
# Script to install an Openshift Cluster
##

## Download Openshift Installer
curl -o /tmp/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.9/openshift-client-linux.tar.gz
tar -zxvf /tmp/openshift-client-linux.tar.gz oc

## Download Openshift Cli
curl -o /tmp/openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.9/openshift-install-linux.tar.gz
tar -zxvf /tmp/openshift-install-linux.tar.gz openshift-install

## Create a specific folder and install config file
mkdir ${CLUSTER_FOLDER}
cat <<EOF > ${CLUSTER_FOLDER}/install-config.yaml
apiVersion: v1
baseDomain: ${CLUSTER_DOMAIN}
metadata:
  name: ${CLUSTER_NAME}
platform:
  aws:
    region: ${CLUSTER_REGION}
pullSecret: '${PULL_SECRET}'
sshKey: ${SSH_KEY}
networking: 
  clusterNetwork:
  - cidr: ${CLUSTER_POD_NET}
    hostPrefix: 23
  machineNetwork:
  - cidr: ${CLUSTER_HOSTS_NET}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${CLUSTER_SRV_NET}
EOF

## Install Openshift Cluster
./openshift-install create cluster --dir=${CLUSTER_FOLDER}