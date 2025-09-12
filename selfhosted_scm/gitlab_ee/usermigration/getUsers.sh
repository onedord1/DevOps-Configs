#!/bin/bash

old_gitlab_token="glpat-qzsbQpkbEY8o5vitx1ZS"
old_gitlab_url="https://172.17.18.200"
output_file="users_export.txt"

> "$output_file"  

page=1
while :; do
  response=$(curl -sk --header "PRIVATE-TOKEN: $old_gitlab_token" "$old_gitlab_url/api/v4/users?per_page=100&page=$page")
  count=$(echo "$response" | jq length)

  if [ "$count" -eq 0 ]; then
    break
  fi

  echo "$response" | jq -r '.[] | [.name, .username, .email] | @csv' >> "$output_file"
  ((page++))
done

echo "Exported users to $output_file"
