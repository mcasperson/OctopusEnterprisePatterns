#!/bin/bash
declare -a arr=("Initialise Space" "Provision Azure Web App" "Provision Azure Web App (CaC)" "Provision Azure Logs")

for i in "${arr[@]}"
do
  # Reset the project versioning, as package based versioning prevents steps from being cleared
  PROJECT_ID=$(curl --silent -G --data-urlencode "name=$i" -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/projects | jq -r ".Items[0].Id")
  if [[ -n "${PROJECT_ID}" && "${PROJECT_ID}" != "null" ]]; then
    DEPLOYMENT_SETTINGS=$(curl --silent -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/projects/${PROJECT_ID}/DeploymentSettings)
    DEPLOYMENT_SETTINGS_BASIC_VERSIONING=$(echo ${DEPLOYMENT_SETTINGS} | jq '.VersioningStrategy.Template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.NextPatch}" | .VersioningStrategy.DonorPackageStepId = null | .VersioningStrategy.DonorPackage = null')
    NEW_DEPLOYMENT_SETTINGS=$(curl --silent -X PUT -d "${DEPLOYMENT_SETTINGS_BASIC_VERSIONING}" -H "Content-Type: application/json" -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/projects/${PROJECT_ID}/DeploymentSettings)
  fi

  # Clear the steps
  DEPLOYMENT_PROCESS_ID=$(curl --silent -G --data-urlencode "name=$i" -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/projects | jq -r ".Items[0].DeploymentProcessId")
  if [[ -n "${DEPLOYMENT_PROCESS_ID}" && "${DEPLOYMENT_PROCESS_ID}" != "null" ]]; then
    echo "Emptying project deploy process ${DEPLOYMENT_PROCESS_ID} for project $i"
    DEPLOYMENT_PROCESS=$(curl --silent -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/deploymentprocesses/${DEPLOYMENT_PROCESS_ID})
    EMPTY_DEPLOYMENT_PROCESS=$(echo ${DEPLOYMENT_PROCESS} | jq 'del(.Steps[])')
    NEW_DEPLOYMENT_PROCESS=$(curl --silent -X PUT -d "${EMPTY_DEPLOYMENT_PROCESS}" -H "Content-Type: application/json" -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" $OCTOPUS_URL/api/$OCTOPUS_SPACE/deploymentprocesses/${DEPLOYMENT_PROCESS_ID})
  fi
done