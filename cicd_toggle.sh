#!/bin/bash

# Configuration
ADMIN_URL="http://localhost:3000/api/maintenance"

# Usage check
if [ "$#" -ne 2 ]; then
    echo "Usage: ./cicd_toggle.sh <SCOPE> <ON|OFF>"
    echo "Example: ./cicd_toggle.sh LEARNER ON"
    exit 1
fi

SCOPE=$1
STATE=$2

if [ "$STATE" == "ON" ]; then
    ACTIVE="true"
    MESSAGE="🚀 Deployment in progress. Please check back in 5 minutes."
    echo "Enabling Maintenance for $SCOPE..."
else
    ACTIVE="false"
    MESSAGE="System Operational"
    echo "Disabling Maintenance for $SCOPE..."
fi

# Make the API call
curl -s -X POST $ADMIN_URL \
  -H "Content-Type: application/json" \
  -d "{
    \"scope\": \"$SCOPE\",
    \"active\": $ACTIVE,
    \"message\": \"$MESSAGE\"
  }" | jq .

echo "" # Newline
