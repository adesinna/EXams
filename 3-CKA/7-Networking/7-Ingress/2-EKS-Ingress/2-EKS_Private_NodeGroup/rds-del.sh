#!/bin/bash

# Variables
CLUSTER_NAME="test1"
REGION="us-west-1"
DB_INSTANCE_IDENTIFIER="usermgmtdb"
DB_SUBNET_GROUP_NAME="eks-rds-db-subnetgroup"
DB_SECURITY_GROUP_NAME="eks_rds_db_sg"

# Set backup retention period to 0 to prevent retaining automated backups
echo "Setting backup retention period to 0 days..."
aws rds modify-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --backup-retention-period 0 \
    --apply-immediately \
    --region $REGION

# Delete the RDS Database Instance
echo "Deleting RDS Database Instance..."
aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --skip-final-snapshot \
    --region $REGION

# Wait for the RDS instance to be deleted
echo "Waiting for RDS instance to be deleted..."
aws rds wait db-instance-deleted --db-instance-identifier $DB_INSTANCE_IDENTIFIER --region $REGION

# Delete any manual snapshots
echo "Listing and deleting manual snapshots for RDS instance $DB_INSTANCE_IDENTIFIER..."
SNAPSHOT_IDS=$(aws rds describe-db-snapshots --db-instance-identifier $DB_INSTANCE_IDENTIFIER --snapshot-type manual --query "DBSnapshots[].DBSnapshotIdentifier" --output text --region $REGION)

if [ -z "$SNAPSHOT_IDS" ]; then
    echo "No manual snapshots found for RDS instance $DB_INSTANCE_IDENTIFIER."
else
    for SNAPSHOT_ID in $SNAPSHOT_IDS; do
        echo "Deleting snapshot $SNAPSHOT_ID..."
        aws rds delete-db-snapshot --db-snapshot-identifier $SNAPSHOT_ID --region $REGION
    done
fi

# Delete the DB Subnet Group
echo "Deleting DB Subnet Group $DB_SUBNET_GROUP_NAME..."
aws rds delete-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --region $REGION

# Retrieve the Security Group ID
echo "Retrieving Security Group ID for $DB_SECURITY_GROUP_NAME..."
DB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$DB_SECURITY_GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text --region $REGION)

if [ "$DB_SECURITY_GROUP_ID" != "None" ] && [ -n "$DB_SECURITY_GROUP_ID" ]; then
    # Delete the DB Security Group
    echo "Deleting DB Security Group $DB_SECURITY_GROUP_NAME..."
    aws ec2 delete-security-group \
        --group-id $DB_SECURITY_GROUP_ID \
        --region $REGION
else
    echo "Security Group $DB_SECURITY_GROUP_NAME not found or already deleted."
fi

echo "Resources deleted successfully."
