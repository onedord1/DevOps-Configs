#!/bin/bash

token="glpat-qzsbQpkbEY8o5vitx1ZS"

response=$(curl -sk --header "PRIVATE-TOKEN: $token" "https://172.17.18.200/api/v4/projects?per_page=2000&page=1")

paths=($(echo "$response" | jq -r '.[].path_with_namespace'))

echo "Project Paths:"
for path in "${paths[@]}"; do
    echo "- $path"
    echo $path >> ./projects.txt
done
