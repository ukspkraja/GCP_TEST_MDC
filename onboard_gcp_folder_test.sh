#!/usr/bin/env bash
# filepath: onboard_gcp_folder_to_mdc.sh

set -euo pipefail

# ====== CONFIG ======
FOLDER_ID="93604753456"
WORKLOAD_IDENTITY_POOL_ID="1172494f68e247438ebbb6916a1c681e"
AZ_SUBSCRIPTION="f2e26c0b-8b27-4edd-b6f4-73edc39a4186"
AZ_RG="kpmg-testing"
AZ_LOCATION="eastus"

CSPM_SA="microsoft-defender-cspm@$FOLDER_ID.iam.gserviceaccount.com"
DEFENDER_SA="microsoft-defender-for-servers@$FOLDER_ID.iam.gserviceaccount.com"

CONNECTOR_NAME="gcp-folder-$FOLDER_ID"

AZ_TOKEN=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)

BODY=$(cat <<EOF
{
  "location": "$AZ_LOCATION",
  "kind": "gcp",
  "properties": {
    "hierarchyIdentifier": "folders/$FOLDER_ID",
    "environmentName": "Gcp",
    "environmentData": {
      "environmentType": "GcpFolder",
      "folderId": "$FOLDER_ID",
      "folderNumber": $FOLDER_ID,
      "workloadIdentityPoolId": "$WORKLOAD_IDENTITY_POOL_ID"
    },
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "serviceAccountEmailAddress": "$CSPM_SA",
          "workloadIdentityProviderId": "cspm"
        }
      },
      {
        "offeringType": "DefenderForServersGcp",
        "defenderForServers": {
          "serviceAccountEmailAddress": "$DEFENDER_SA",
          "workloadIdentityProviderId": "defender-for-servers"
        },
        "mdeAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "subPlan": "P2"
      }
    ]
  }
}
EOF
)

echo "Request body:"
echo "$BODY"

echo "Creating folder-level connector $CONNECTOR_NAME in Azure ..."
curl -s -X PUT \
  -H "Authorization: Bearer $AZ_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "https://management.azure.com/subscriptions/$AZ_SUBSCRIPTION/resourceGroups/$AZ_RG/providers/Microsoft.Security/securityConnectors/$CONNECTOR_NAME?api-version=2023-10-01-preview"

echo "✅ Folder-level connector created for folder $FOLDER_ID"
