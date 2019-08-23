#!/bin/bash
set -e

# Terraform resource name of the resource group block where you want to move your state to
# e.g. terraform state mv module.api.azurerm_resource_group.rg azurerm_resource_group.rg
DEST_RG=$1

# Terraform resource name of the app insights block where you want to move your state to
# e.g. terraform state mv module.api.azurerm_application_insights.appinsights azurerm_application_insights.appinsights
DEST_APPINSIGHTS=${2-""}


STORAGE_ACCOUNT_NAME=$3
ENV=$4
APP_FULLL_NAME=$5
DEST_CONTAINER_NAME=$6
SUBSCRIPTION=$7

TIMESTAMP=`date "+%Y%m%d"`

echo "Backing up remote state..."
env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$SUBSCRIPTION az storage blob copy start --account-name ${STORAGE_ACCOUNT_NAME} --destination-blob ${APP_FULLL_NAME}/${ENV}/terraform.tfstate.backup.${TIMESTAMP} --destination-container ${DEST_CONTAINER_NAME} --source-uri https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${DEST_CONTAINER_NAME}/${APP_FULLL_NAME}/${ENV}/terraform.tfstate

sleep 15

function usage() {
  echo "usage: ./terraform_state_mv.sh <DEST_RG> <DEST_APPINSIGHTS> <STORAGE_ACCOUNT_NAME> <ENV> <APP_FULLL_NAME> <DEST_CONTAINER_NAME> <SUBSCRIPTION>"
}

echo "Initiating terraform state move...."
if [ -z ${DEST_RG} ]
then 
    echo -e "ERROR: Destination resource group should not be empty"
    usage
else
    terraform state mv module.api.azurerm_resource_group.rg azurerm_resource_group.${DEST_RG}
fi

if [ -z ${DEST_APPINSIGHTS} ]
then 
    echo "App insights state not moved as destination App insights is empty."
    exit 0
else
    terraform state mv module.api.azurerm_application_insights.appinsights azurerm_application_insights.${DEST_APPINSIGHTS}
fi
