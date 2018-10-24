#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
COLOR=$2
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# Let jenkins do its thing
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod

# Set up a MongoDB cluster in the production project
oc create -f ./Infrastructure/templates/mongo.yaml

# important, setup green first
chmod +x ./Infrastructure/bin/setup_prod_bluegreen.sh
./Infrastructure/bin/setup_prod_bluegreen.sh ${GUID} green
./Infrastructure/bin/setup_prod_bluegreen.sh ${GUID} blue