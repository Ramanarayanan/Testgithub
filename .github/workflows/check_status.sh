#!/bin/bash

# Function to check the status of a GitHub Actions job
check_job_status() {
  job_status=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/jobs/$1" | jq -r '.conclusion')
  echo "$job_status"
}

# Array containing all job names
job_names=("Build_NUnitTests" "Build_Manual" "New_Build_Deployment") 

# Loop until all jobs have succeeded
while true; do
  all_succeeded=true

  for job_name in "${job_names[@]}"; do
    job_id=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$GITHUB_WORKFLOW/runs" | jq -r --arg job_name "$job_name" '.workflow_runs[] | select(.name == $job_name) | .id')

    job_status=$(check_job_status "$job_id")

    if [ "$job_status" != "success" ]; then
      all_succeeded=false
      break
    fi
  done

  if [ "$all_succeeded" = true ]; then
    break
  fi

  echo "Not all jobs have succeeded yet. Waiting..."
  sleep 30
done

echo "All jobs have succeeded!"
