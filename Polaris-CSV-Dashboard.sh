#!/bin/bash

# note requires jq
# brew install jq

if [ $# -ne 2 ]; then
  echo "Usage: $0 <HOST> <API_TOKEN>"
  exit 1
fi

polarisHost="$1"
apiToken="$2"

app_csv_filename="app-dashboard.csv"
project_csv_filename="project-dashboard.csv"
offset="0"
app_csv_headers="id,tenantId,portfolioId,portfolioItemId,portfolioItemName,criticalIssueCount,highIssueCount,mediumIssueCount,lowIssueCount,informationalIssueCount,totalIssueCount"
project_csv_headers="id,tenantId,portfolioId,portfolioItemId,portfolioSubItemId,portfolioSubItemName,criticalIssueCount,highIssueCount,mediumIssueCount,lowIssueCount,informationalIssueCount,totalIssueCount"

portfolioLookup=$(curl -s --location \
        "https://$polarisHost/api/portfolio/portfolios" \
        --header "Api-Token: $apiToken")
        
portfolioID=$(echo "$portfolioLookup" | jq -r '._items[0].id')

while true; do

    app_json_output=$(curl -s --location \
        "https://$polarisHost/api/portfolio/portfolios/$portfolioID/dashboard?_limit=100&_offset=$offset" \
        --header "Api-Token: $apiToken")

    new_app_csv_output=$(echo "$app_json_output" | jq -r '.["_items"][] | [.id, .tenantId, .portfolioId, .portfolioItemId, .portfolioItemName, .criticalIssueCount, .highIssueCount, .mediumIssueCount, .lowIssueCount, .informationalIssueCount, .totalIssueCount] | @csv')

    new_app_csv_output=$(echo "$new_app_csv_output")
        
    if [ -n "$new_app_csv_output" ]; then
    	if [ -n "$app_csv_output" ]; then
    		app_csv_output="${app_csv_output}\n${new_app_csv_output}"
    	else
    		app_csv_output="${new_app_csv_output}"
    	fi
   	fi
    
	portfolioItemIDs=$(echo "$app_json_output" | jq -r '._items[].portfolioItemId')
	
    for itemID in $portfolioItemIDs; do
    
        project_json_output=$(curl -s --location \
            "https://$polarisHost/api/portfolio/portfolios/$portfolioID/portfolio-items/$itemID/dashboard?_pagingOffset=0" \
            --header "Api-Token: $apiToken")
            
    	new_project_csv_output=$(echo "$project_json_output" | jq -r '.["_items"][] | [.id, .tenantId, .portfolioId, .portfolioItemId, .portfolioSubItemId, .portfolioSubItemName, .criticalIssueCount, .highIssueCount, .mediumIssueCount, .lowIssueCount, .informationalIssueCount, .totalIssueCount] | @csv')

   		new_project_csv_output=$(echo "$new_project_csv_output")
   		
   		if [ -n "$new_project_csv_output" ]; then
   			if [ -n "$project_csv_output" ]; then
   				project_csv_output="${project_csv_output}\n${new_project_csv_output}"
   			else
   				project_csv_output="${new_project_csv_output}"
   			fi
   		fi
   		    
    done
    
    offset=$((offset + 100))
        
    currentPage=$(echo "$app_json_output" | jq -r '._collection.currentPage')
    pageCount=$(echo "$app_json_output" | jq -r '._collection.pageCount')

    if [ "$currentPage" -lt "$pageCount" ]; then
        continue 
    else
        break   
    fi
done

app_csv_output="${app_csv_headers}\n${app_csv_output}"
echo -e "$app_csv_output" > "$app_csv_filename"

project_csv_output="${project_csv_headers}\n${project_csv_output}"
echo -e "$project_csv_output" > "$project_csv_filename"
