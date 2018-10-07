#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# IMPORTANT: Switching to a project can lead to creating resources in other projects because of parallel pipelines.. yikes. 
# Use -n flag for all oc commands

# create app from template, this will create everything we need
oc new-app -f ./Infrastructure/templates/sonar.yaml -p GUID=${GUID} -n $GUID-sonarqube
sleep 10
