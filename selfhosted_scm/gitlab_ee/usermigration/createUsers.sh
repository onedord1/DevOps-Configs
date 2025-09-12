#!/bin/bash

new_gitlab_token="glpat-SzCUVkxGqp98LsQeWVii"
new_gitlab_url="https://gitlab.aes-core.com"
input_file="test.txt"


while IFS=',' read -r name username email; do
    name=$(echo "$name" | tr -d '"')
    username=$(echo "$username" | tr -d '"')
    email=$(echo "$email" | tr -d '"')

    password="RandomPassword123resetplease"

    echo "Creating user: $username <$email>"

    result=$(curl -sk --write-out "%{http_code}" --output /tmp/create_user_output \
         --request POST "$new_gitlab_url/api/v4/users" \
         --header "PRIVATE-TOKEN: $new_gitlab_token" \
         --form "email=$email" \
         --form "username=$username" \
         --form "name=$name" \
         --form "password=$password" \
         --form "skip_confirmation=true" \ 
         --form "reset_password=true")

    if [[ "$result" == "201" ]]; then
        echo "$name,$username,$email,$password"
    else
        echo " Failed to create user $username: HTTP $result"
        cat /tmp/create_user_output
    fi

done < "$input_file"

echo " Created user"
