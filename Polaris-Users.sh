#!/bin/bash

# note requires jq
# brew install jq

if [ $# -ne 2 ]; then
  echo "Usage: $0 <HOST> <API_TOKEN>"
  exit 1
fi

polarisHost="$1"
apiToken="$2"

offset="0"
csv_headers="id,organizationId,email,firstName,lastName,enabled"

while true; do

    json_output=$(curl "https://$polarisHost/api/ciam/users?_limit=100&_offset=$offset" \
        -X "GET" \
        -H "Accept: application/vnd.synopsys.ciam.user-1+json" \
        --header "Api-Token: $apiToken")

    new_csv_output=$(echo "$json_output" | jq -r '.["_items"][] | [.id, .organizationId, .email, .firstName, .lastName, .enabled] | @csv')
    new_csv_output=$(echo "$new_csv_output")

    if [ -n "$new_csv_output" ]; then
    	if [ -n "$csv_output" ]; then
    		csv_output="${csv_output}\n${new_csv_output}"
    	else
    		csv_output="${new_csv_output}"
    	fi
    fi
	
    offset=$((offset + 5))
        
    hasNextPage=$(echo "$json_output" | jq -r '._collection.hasNextPage')

    if [ "$hasNextPage" == "true" ]; then
        continue 
    else
        break   
    fi
done

csv_output="${csv_headers}\n${csv_output}"
echo -e "$csv_output" > "Users.csv"
