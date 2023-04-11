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
done