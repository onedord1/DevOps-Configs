#!/bin/bash

# GitLab configuration
GITLAB_URL="https://17.1.1.47"
PROJECT_ID="214"
PRIVATE_TOKEN="gat-yi_hMHUr7R"

# Array of variables: key=value pairs
declare -A VARIABLES=(
    ["DOCKER_AUTH_CONFIG"]='{
        "auths": {
                "registry.cloudaes.com": {
                        "auth": "cm9ib3Qkc2tvcYhdGlhMllWQ0WQ5adjTVM5emlKdmSA=="
                }
        }
    }'
    ["GOOGLE_CHAT_WEBHOOK_URL"]="https://chat.googleapis.com/v1/spaces/AAQAuKvWB60/messages?key=AS6vySjMm-WEfRKqqsHI&n=CcctFoLt64rIFS_KbHA4"
    ["NEXUS_PASS"]="9Cj5fjy2t"
    ["NEXUS_USER"]="developer"
    ["SONAR_TOKEN"]="sqa_2d542b43a89d07284"
    ["SONAR_URL"]="https://sonarqube.quickops.io"
    ["argo_pass"]="Dev@1235"
    ["argo_user"]="developer"
    ["dev_argo_url"]="17.1.1.3:32106"
    ["gitpass"]="stHeRIigRAinEa"
    ["gituser"]="gitlabcicd"
    ["harborpass"]="a2Yzm1qRy7ziJ5WfH"
    ["harboruser"]="robot\$quickops-automation"
    ["main_argo_url"]="17.7.9.1:3088"
    ["qa_argo_url"]="17.17.7.15:3108"
    ["SIGNOZ_USERNAME"]="signoz"
    ["SIGNOZ_PASSWORD"]="Sinz@1246"
)

# Create each variable
for key in "${!VARIABLES[@]}"; do
    echo "Creating variable: $key"
    
    # Create a temporary file to store the response
    temp_file=$(mktemp)
    
    # Make the curl request and capture both the response body and HTTP status code
    http_code=$(curl -k --request POST \
        --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/variables" \
        --form "key=$key" \
        --form "value=${VARIABLES[$key]}" \
        --silent --output "$temp_file" --write-out "%{http_code}")
    
    # Read the response body from the temporary file
    response_body=$(cat "$temp_file")
    
    # Clean up the temporary file
    rm -f "$temp_file"
    
    if [ "$http_code" -eq 201 ]; then
        echo "✓ Successfully created variable: $key"
    else
        echo "✗ Failed to create variable: $key (HTTP $http_code)"
        echo "Response: $response_body"
    fi
    echo "---"
done