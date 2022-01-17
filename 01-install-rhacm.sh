#!/bin/bash
##
# Script to install RHACM operator and Hub
##

NAMESPACE=open-cluster-management

## Create the namespace
./oc new-project ${NAMESPACE}

## Create the Operator Group
cat <<EOF > /tmp/rhacm-operator-group.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${NAMESPACE}-og
  namespace: ${NAMESPACE}
spec:
  targetNamespaces:
  - ${NAMESPACE}
EOF
./oc apply -f /tmp/rhacm-operator-group.yaml

## Create the Operator Subscription
cat <<EOF > /tmp/rhacm-operator-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: advanced-cluster-management
  namespace: ${NAMESPACE}
spec:
  channel: release-2.4
  installPlanApproval: Automatic
  name: advanced-cluster-management
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  #startingCSV: advanced-cluster-management.v2.4.1
EOF
./oc apply -f /tmp/rhacm-operator-subscription.yaml

## Wait for operator to be ready
sleep 300

## Create RHACM object
cat <<EOF > /tmp/mch.yaml
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: ${NAMESPACE}
spec: {}
EOF
./oc apply -f /tmp/mch.yaml
