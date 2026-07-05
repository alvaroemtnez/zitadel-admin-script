#!/bin/bash

echo "=== ZITADEL Admin Utility ==="
echo ""

# ==============================================================================
# CONFIGURATION
# You can hardcode your variables here. 
# Note: Environment variables (ZITADEL_DOMAIN, ZITADEL_PAT) will override these.
# ==============================================================================
SCRIPT_DOMAIN=""
SCRIPT_PAT=""
# ==============================================================================

# 1. Resolve ZITADEL Domain
FINAL_DOMAIN="${ZITADEL_DOMAIN:-$SCRIPT_DOMAIN}"
if [ -z "$FINAL_DOMAIN" ]; then
    read -p "Enter your ZITADEL Domain (without https://): " FINAL_DOMAIN
else
    echo "Using ZITADEL Domain from configuration: $FINAL_DOMAIN"
fi

# 2. Resolve Access Token
FINAL_PAT="${ZITADEL_PAT:-$SCRIPT_PAT}"
if [ -z "$FINAL_PAT" ]; then
    read -s -p "Enter your Access Token (PAT): " FINAL_PAT
    echo "" 
else
    echo "Using Access Token (PAT) from configuration."
fi

# Helper function to resolve a User ID from Email or Username
resolve_user_id() {
    local USER_INPUT=$1
    TARGET_USER_ID=""
    
    echo "Resolving user identity..."
    
    local SEARCH_RESPONSE=$(curl -s -X POST "https://${FINAL_DOMAIN}/v2/users" \
         -H "Authorization: Bearer ${FINAL_PAT}" \
         -H "Content-Type: application/json" \
         -d '{
               "query": { "limit": 1 },
               "queries": [
                 {
                   "orQuery": {
                     "queries": [
                       {
                         "userNameQuery": {
                           "userName": "'"$USER_INPUT"'",
                           "method": "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"
                         }
                       },
                       {
                         "emailQuery": {
                           "emailAddress": "'"$USER_INPUT"'",
                           "method": "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"
                         }
                       }
                     ]
                   }
                 }
               ]
             }')

    if command -v jq &> /dev/null; then
        TARGET_USER_ID=$(echo "$SEARCH_RESPONSE" | jq -r 'if .result and (.result | length > 0) then .result[0].userId else empty end')
    else
        TARGET_USER_ID=$(echo "$SEARCH_RESPONSE" | grep -o '"userId"[ :] *"[^"]*"' | head -1 | sed 's/.*"userId"[ :] *"\([^"]*\)"/\1/')
    fi

    if [ -n "$TARGET_USER_ID" ] && [ "$TARGET_USER_ID" != "null" ]; then
        echo "Resolved '$USER_INPUT' to User ID: $TARGET_USER_ID"
    else
        TARGET_USER_ID="$USER_INPUT"
    fi
}

# Main Menu Loop
while true; do
    echo ""
    echo "------------------------------------------------"
    echo "Select an action:"
    echo "1) Generate Recovery Codes"
    echo "2) Trigger Password Reset"
    echo "3) Change Instance Name"
    echo "0) Exit"
    read -p "Action [0-3]: " ACTION

    case $ACTION in
        1)
            echo ""
            echo "--- Generate Recovery Codes ---"
            read -p "Enter the target Username, Email, or User ID: " USER_INPUT
            resolve_user_id "$USER_INPUT"
            
            read -p "Enter the number of codes to generate (1-50) [Default: 10]: " CODE_COUNT
            CODE_COUNT=${CODE_COUNT:-10}
            
            echo "Generating $CODE_COUNT recovery codes for User ID: $TARGET_USER_ID..."
            RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "https://${FINAL_DOMAIN}/v2/users/${TARGET_USER_ID}/recovery_codes" \
                 -H "Authorization: Bearer ${FINAL_PAT}" \
                 -H "Content-Type: application/json" \
                 -d "{\"count\": ${CODE_COUNT}}")
            
            HTTP_BODY=$(echo "$RESPONSE" | sed -e '$d')
            HTTP_STATUS=$(echo "$RESPONSE" | tail -n1 | sed -e 's/HTTP_STATUS://')
            
            if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ]; then
                echo "Success!"
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            else
                echo "API Call Failed (Status Code: $HTTP_STATUS)"
                echo "Error Details:"
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            fi
            ;;
        2)
            echo ""
            echo "--- Trigger Password Reset ---"
            read -p "Enter the target Username, Email, or User ID: " USER_INPUT
            resolve_user_id "$USER_INPUT"
            
            echo "Triggering password reset email for User ID: $TARGET_USER_ID..."
            # Using the sendLink object to trigger ZITADEL's default email flow
            RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "https://${FINAL_DOMAIN}/v2/users/${TARGET_USER_ID}/password_reset" \
                 -H "Authorization: Bearer ${FINAL_PAT}" \
                 -H "Content-Type: application/json" \
                 -d '{"sendLink": {}}')
            
            HTTP_BODY=$(echo "$RESPONSE" | sed -e '$d')
            HTTP_STATUS=$(echo "$RESPONSE" | tail -n1 | sed -e 's/HTTP_STATUS://')
            
            if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ]; then
                echo "Success! Password reset link sent via configured notification channels."
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            else
                echo "API Call Failed (Status Code: $HTTP_STATUS)"
                echo "Error Details:"
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            fi
            ;;
        3)
            echo ""
            echo "--- Change Instance Name ---"
            read -p "Enter the new Instance Name: " NEW_INSTANCE_NAME
            
            echo "Updating instance name to: $NEW_INSTANCE_NAME..."
            RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "https://${FINAL_DOMAIN}/zitadel.instance.v2.InstanceService/UpdateInstance" \
                 -H "Authorization: Bearer ${FINAL_PAT}" \
                 -H "Content-Type: application/json" \
                 -H "Connect-Protocol-Version: 1" \
                 -d "{ \"instanceName\": \"${NEW_INSTANCE_NAME}\" }")
            
            HTTP_BODY=$(echo "$RESPONSE" | sed -e '$d')
            HTTP_STATUS=$(echo "$RESPONSE" | tail -n1 | sed -e 's/HTTP_STATUS://')
            
            if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ]; then
                echo "Success! Instance name updated."
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            else
                echo "API Call Failed (Status Code: $HTTP_STATUS)"
                echo "Error Details:"
                if command -v jq &> /dev/null; then echo "$HTTP_BODY" | jq .; else echo "$HTTP_BODY"; fi
            fi
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please enter a number between 0 and 3."
            ;;
    esac
done
