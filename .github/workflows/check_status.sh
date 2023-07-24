#!/bin/bash

# Function to check the status of a GitHub Actions workflow
check_workflow_status() {
  workflow_status=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$1" | jq -r '.conclusion')
  echo "$workflow_status"
}

# Array containing all dependent workflow names
workflow_names=("Build_NUnitTests.yml" "Build_Manual.yml" "New_Build_Deployment.yml") # Add other workflow names as needed

# Function to trigger the dependent workflows
trigger_dependent_workflows() {
  for workflow_name in "${workflow_names[@]}"; do
    curl -X POST -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$workflow_name/dispatches" \
      -d '{"ref": "main"}'
  done
}

# Trigger the dependent workflows
trigger_dependent_workflows

# Loop until all dependent workflows have succeeded
while true; do
  all_succeeded=true

  for workflow_name in "${workflow_names[@]}"; do
    workflow_id=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows" | jq -r --arg workflow_name "$workflow_name" '.workflows[] | select(.path == $workflow_name) | .id')

    workflow_status=$(check_workflow_status "$workflow_id")

    if [ "$workflow_status" != "success" ]; then
      all_succeeded=false
      break
    fi
  done

  if [ "$all_succeeded" = true ]; then
    break
  fi

  echo "Not all dependent workflows have succeeded yet. Waiting..."
  sleep 30
done

echo "All dependent workflows have succeeded!"
