#!/bin/bash
##
# Script to install and configure Submariner
##

NAMESPACE=open-cluster-management

## Create AWS credentials and submariner config in order to be able to prepare AWS account for the new connections
## CLUSTER 1
cat <<EOF > /tmp/rhacm-cluster1-aws-cred.yaml
apiVersion: v1
kind: Secret
metadata:
    name: cluster1-aws-creds
    namespace: cluster1
type: Opaque
data:
    aws_access_key_id: $(echo -n ${AWS_ACCESS_KEY_ID} | base64 -w0)
    aws_secret_access_key: $(echo -n ${AWS_SECRET_ACCESS_KEY} | base64 -w0)
EOF
./oc apply -f /tmp/rhacm-cluster1-aws-cred.yaml

cat <<EOF > /tmp/rhacm-cluster1-submariner-conf.yaml
apiVersion: submarineraddon.open-cluster-management.io/v1alpha1
kind: SubmarinerConfig
metadata:
    name: submariner
    namespace: cluster1
spec:
    credentialsSecret:
      name: cluster1-aws-creds
EOF
./oc apply -f /tmp/rhacm-cluster1-submariner-conf.yaml

## Create AWS credentials and submariner config in order to be able to prepare AWS account for the new connections
## CLUSTER 2
cat <<EOF > /tmp/rhacm-cluster2-aws-cred.yaml
apiVersion: v1
kind: Secret
metadata:
    name: cluster2-aws-creds
    namespace: cluster2
type: Opaque
data:
    aws_access_key_id: $(echo -n ${AWS_ACCESS_KEY_ID} | base64 -w0)
    aws_secret_access_key: $(echo -n ${AWS_SECRET_ACCESS_KEY} | base64 -w0)
EOF
./oc apply -f /tmp/rhacm-cluster2-aws-cred.yaml

cat <<EOF > /tmp/rhacm-cluster2-submariner-conf.yaml
apiVersion: submarineraddon.open-cluster-management.io/v1alpha1
kind: SubmarinerConfig
metadata:
    name: submariner
    namespace: cluster2
spec:
    credentialsSecret:
      name: cluster2-aws-creds
EOF
./oc apply -f /tmp/rhacm-cluster2-submariner-conf.yaml

sleep 120
./oc get -n cluster2 submarinerconfig.submarineraddon.open-cluster-management.io/submariner -o jsonpath='{.status}'
./oc get -n cluster1 submarinerconfig.submarineraddon.open-cluster-management.io/submariner -o jsonpath='{.status}'

## Create submariner ManagedClusterSet
cat <<EOF > /tmp/rhacm-submariner.yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ManagedClusterSet
metadata:
  name: submariner
EOF
./oc apply -f /tmp/rhacm-submariner.yaml


## Label cluster namespaces to added to the ManagedClusterSet
./oc label managedclusters cluster1 "cluster.open-cluster-management.io/clusterset=submariner" --overwrite
./oc label managedclusters cluster2 "cluster.open-cluster-management.io/clusterset=submariner" --overwrite


## Create Submariner in every cluster
cat <<EOF > /tmp/rhacm-submariner-cluster1.yaml
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: ManagedClusterAddOn
metadata:
     name: submariner
     namespace: cluster1
spec:
     installNamespace: submariner-operator
EOF
./oc apply -f /tmp/rhacm-submariner-cluster1.yaml

cat <<EOF > /tmp/rhacm-submariner-cluster2.yaml
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: ManagedClusterAddOn
metadata:
     name: submariner
     namespace: cluster2
spec:
     installNamespace: submariner-operator
EOF
./oc apply -f /tmp/rhacm-submariner-cluster2.yaml


## Waiting for managed clusters submariner solutions are deployed
sleep 120
./oc -n cluster1 get managedclusteraddons submariner -oyaml
./oc -n cluster2 get managedclusteraddons submariner -oyaml