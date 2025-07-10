#!/bin/bash

# Variables
CLUSTER_NAME="test1"
REGION="us-west-1"
DB_INSTANCE_IDENTIFIER="usermgmtdb"
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0.35"
DB_INSTANCE_CLASS="db.t3.micro"
DB_NAME="usermgmtdb"
DB_USERNAME="dbadmin"
DB_PASSWORD="dbpassword11"
DB_PORT=3306
DB_SECURITY_GROUP_NAME="eks_rds_db_sg"
DB_SECURITY_GROUP_DESC="Allow access for RDS Database from EKS worker nodes"
DB_SUBNET_GROUP_NAME="eks-rds-db-subnetgroup"
DB_SUBNET_GROUP_DESC="EKS RDS DB Subnet Group"

# Get the VPC ID of the EKS cluster
echo "Retrieving VPC ID associated with EKS cluster..."
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
  echo "VPC not found for the EKS cluster. Please check the cluster name and try again."
  exit 1
fi

echo "VPC ID: $VPC_ID"

# Retrieve the private subnet IDs where the EKS worker nodes are running
echo "Retrieving private subnet IDs across different Availability Zones..."
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[?MapPublicIpOnLaunch==\`false\`].SubnetId" \
    --output text --region $REGION)

if [ -z "$PRIVATE_SUBNET_IDS" ]; then
  echo "No private subnets found for the EKS worker nodes. Please ensure your EKS nodes are in private subnets."
  exit 1
fi

echo "Using private subnets: $PRIVATE_SUBNET_IDS"

# Get the CIDR blocks of the private subnets
EKS_SUBNET_CIDRS=$(aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_IDS --query "Subnets[].CidrBlock" --output text --region $REGION)

if [ -z "$EKS_SUBNET_CIDRS" ]; then
  echo "No CIDR blocks found for the specified subnets. Please ensure your EKS nodes are in private subnets."
  exit 1
fi

# Check if the DB Security Group already exists
echo "Checking if DB Security Group already exists..."
DB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$DB_SECURITY_GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text --region $REGION)

if [ "$DB_SECURITY_GROUP_ID" == "None" ] || [ -z "$DB_SECURITY_GROUP_ID" ]; then
  # Create the DB Security Group if it doesn't exist
  echo "Creating DB Security Group..."
  DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $DB_SECURITY_GROUP_NAME --description "$DB_SECURITY_GROUP_DESC" --vpc-id $VPC_ID --query "GroupId" --output text --region $REGION)

  # Add inbound rules to the Security Group to allow MySQL access only from EKS subnets
  for CIDR in $EKS_SUBNET_CIDRS; do
    echo "Allowing MySQL access from CIDR $CIDR..."
    aws ec2 authorize-security-group-ingress --group-id $DB_SECURITY_GROUP_ID --protocol tcp --port $DB_PORT --cidr $CIDR --region $REGION
  done
else
  echo "DB Security Group already exists with ID: $DB_SECURITY_GROUP_ID"
fi

# Check if the DB Subnet Group already exists
echo "Checking if DB Subnet Group already exists..."
DB_SUBNET_GROUP_EXISTS=$(aws rds describe-db-subnet-groups --db-subnet-group-name $DB_SUBNET_GROUP_NAME --query "DBSubnetGroups[0].DBSubnetGroupName" --output text --region $REGION)

if [ "$DB_SUBNET_GROUP_EXISTS" == "None" ] || [ -z "$DB_SUBNET_GROUP_EXISTS" ]; then
  # Create the DB Subnet Group with the retrieved private subnets
  echo "Creating DB Subnet Group..."
  aws rds create-db-subnet-group \
      --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
      --db-subnet-group-description "$DB_SUBNET_GROUP_DESC" \
      --subnet-ids $PRIVATE_SUBNET_IDS \
      --region $REGION
else
  echo "DB Subnet Group already exists: $DB_SUBNET_GROUP_NAME"
fi

# Create the RDS Database Instance without backup, in private subnets
echo "Creating RDS Database Instance without backup..."
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --allocated-storage 20 \
    --db-name $DB_NAME \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --vpc-security-group-ids $DB_SECURITY_GROUP_ID \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --no-publicly-accessible \
    --backup-retention-period 0 \
    --port $DB_PORT \
    --region $REGION

# Wait for the RDS instance to become available
echo "Waiting for RDS instance to be available..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $REGION

# Get the endpoint of the RDS instance
DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --query "DBInstances[0].Endpoint.Address" --output text --region $REGION)

echo "RDS instance created successfully. Endpoint: $DB_ENDPOINT"
