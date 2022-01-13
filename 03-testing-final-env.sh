#!/bin/bash
##
# Deploy and export an application in OCP
## 

./oc new-project jump-app

cat <<EOF > /tmp/jump-app-golang-service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: back-golang
  name: back-golang
  namespace: jump-app
spec:
  ports:
    - name: http-8442
      port: 8442
      protocol: TCP
      targetPort: 8442   
  selector:
    app: back-golang
EOF
./oc apply -f /tmp/jump-app-golang-service.yaml

cat <<EOF > /tmp/jump-app-golang-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: back-golang
    version: v1
  name: back-golang-v1
  namespace: jump-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: back-golang
  template:
    metadata:
      labels:
        name: back-golang-v1
        app: back-golang
        version: v1
    spec:
      containers:
      - image: quay.io/acidonpe/jump-app-back-golang:latest
        imagePullPolicy: Always
        name: back-golang-v1
        ports:
          - containerPort: 8442
            protocol: TCP
        resources: {}
        env:  
          - name: APP_REF_NAME
            value: jump-app
EOF
./oc apply -f /tmp/jump-app-golang-deployment.yaml

cat <<EOF > /tmp/jump-app-golang-route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: back-golang
  namespace: jump-app
spec:
  to:
    kind: Service
    name: back-golang
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  port:
    targetPort: http-8442
EOF
./oc apply -f /tmp/jump-app-golang-route.yaml

cat <<EOF > /tmp/jump-app-golang-service-export.yaml
apiVersion: multicluster.x-k8s.io/v1alpha1
kind: ServiceExport
metadata:
  name: back-golang
  namespace: jump-app
EOF
./oc apply -f /tmp/jump-app-golang-service-export.yaml