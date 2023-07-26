#!/bin/bash

# Check if Offset, API Token, and portfolioID are provided as command-line arguments
if [ $# -ne 5 ]; then
  echo "Usage: $0 <POLARIS_HOST> <POLARIS_TOKEN> <GITHUB_TOKEN> <POLARIS_ENTITLEMENT> <REPO_PREFIX>"
  exit 1
fi

polaris_host="$1"
polaris_token="$2"
gh_token="$3"
entitlement_list="$4"
repo_name_prefix="$5"

# Polaris Portfolio Lookup
portfolioLookup=$(curl -s --location \
        "https://$polaris_host/api/portfolio/portfolios" \
        --header "Api-Token: $polaris_token")
        
portfolioID=$(echo "$portfolioLookup" | jq -r '._items[0].id')
echo "portfolioID: $portfolioID"

portfolio_item_id=""

# GitHub Lookup
ghLookup=$(curl -s --location \
        "https://api.github.com/user/repos" \
        --header "Authorization: token $gh_token" \
        --header "User-Agent: request")

# Loop through each repo element in the GitHub API response
for row in $(echo "$ghLookup" | jq -r '.[] | @base64'); do
    # Extract the base64-encoded JSON object and decode it
    _jq() {
      echo "$row" | base64 --decode | jq -r "$1"
    }

    clone_url=$(_jq '.clone_url')
    name=$(_jq '.name')

    # Echo the GH Repos to the screen for debugging
    echo "Clone URL: $clone_url"
    echo "Name: $name"
     
    # Set the JSON app data with the current repo data"
    data="{ \"name\": \"$repo_name_prefix$name\", \"itemType\": \"APPLICATION\", \"description\": \"$clone_url\" }"
  
    # Make the add application request
    polarisApp=$(curl --location \
        "https://$polaris_host/api/portfolio/portfolios/$portfolioID/portfolio-items" \
         --header "Content-Type: application/vnd.synopsys.pm.portfolio-items-1+json" \
         --header "Api-Token: $polaris_token" \
         --data "$data")

    portfolio_item_id=$(echo "$polarisApp" | jq -r '.id')
    echo "AppID: $portfolio_item_id"
    
    # Set the JSON data entitlement_list
    data="{
	  \"entitlementIds\": [
	    \"$entitlement_list\"
	  ]
	}"
    
    # Make the curl request
    polarisEntitlement=$(curl --location \
        "https://$polaris_host/api/portfolio/portfolio-items/$portfolio_item_id/entitlements" \
        --header "Accept: application/vnd.synopsys.pm.entitlements-2+json" \
        --header "Content-Type: application/vnd.synopsys.pm.entitlements-2+json" \
        --header "Api-Token: $polaris_token" \
         --data "$data")
     
    # Set the project JSON data
    data="{ \"name\": \"$repo_name_prefix$name\", \"subItemType\": \"PROJECT\", \"description\": \"$clone_url\" }"

	# Make the add project request
    polarisProject=$(curl --location \
        "https://$polaris_host/api/portfolio/portfolio-items/$portfolio_item_id/portfolio-sub-items" \
         --header "Content-Type: application/vnd.synopsys.pm.portfolio-subItems-1+json" \
         --header "Api-Token: $polaris_token" \
         --data "$data")
  
    portfolio_sub_item_id=$(echo "$polarisProject" | jq -r '.id')
    echo "ProjectID: $portfolio_sub_item_id"
    
    
    # Set the SCM Integration JSON data for the project
	data="{
	  \"applicationId\": \"$portfolio_item_id\",
	  \"repositoryUrl\": \"$clone_url\",
	  \"scmProvider\": \"GITHUB_STANDARD\",
	  \"scmAuthentication\": {
	    \"authenticationMode\": \"PAT\",
	    \"authToken\": \"$gh_token\"
	  }
	}"
               
   # Make the SCM Integration request
    polarisSCM=$(curl --location \
        "https://$polaris_host/api/scm/projects/$portfolio_sub_item_id/repository" \
		--header "Content-Type: application/vnd.synopsys.scm.repo-1+json" \
		--header "accept: application/vnd.synopsys.scm.repo-1+json" \
		--header "Api-Token: $polaris_token" \
		--data "$data")
        	
done
