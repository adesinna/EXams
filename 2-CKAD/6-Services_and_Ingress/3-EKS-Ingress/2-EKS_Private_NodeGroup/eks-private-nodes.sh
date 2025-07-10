#!/bin/bash

# Variables
CLUSTER_NAME="test1"
REGION="us-west-1"
ZONES="us-west-1a,us-west-1b"
NODEGROUP_NAME="test1-ng-private1"
NODE_TYPE="t3.medium"
NODES=1
NODES_MIN=1
NODES_MAX=2
NODE_VOLUME_SIZE=20
SSH_KEY_NAME="kube-demo" # create key first

# Create EKS cluster with private node group
echo "Creating EKS cluster with private node group..."
eksctl create cluster --name=$CLUSTER_NAME \
                      --region=$REGION \
                      --zones=$ZONES \
                      --nodegroup-name=$NODEGROUP_NAME \
                      --node-type=$NODE_TYPE \
                      --nodes=$NODES \
                      --nodes-min=$NODES_MIN \
                      --nodes-max=$NODES_MAX \
                      --node-volume-size=$NODE_VOLUME_SIZE \
                      --ssh-access \
                      --ssh-public-key=$SSH_KEY_NAME \
                      --managed \
                      --asg-access \
                      --external-dns-access \
                      --full-ecr-access \
                      --appmesh-access \
                      --alb-ingress-access \
                      --node-private-networking

# Associate IAM OIDC provider with the cluster
echo "Associating IAM OIDC provider with the cluster..."
eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --approve

# Confirm that the cluster was created
echo "Listing EKS clusters..."
eksctl get cluster

# Confirm that the node group was created
echo "Listing node groups in the cluster..."
eksctl get nodegroup --cluster=$CLUSTER_NAME

# List the nodes in the cluster
echo "Listing nodes in the cluster..."
kubectl get nodes -o wide

# View the current kubectl context
echo "Viewing the current kubectl context..."
kubectl config view --minify

echo "EKS cluster and private node group setup complete."
