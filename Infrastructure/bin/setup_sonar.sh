#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# switch to the right project first 
oc project ${GUID}-sonarqube

# create app from template, this will create everything we need
oc new-app -f ./Infrastructure/templates/sonar.yaml -p GUID=${GUID}
sleep 10
