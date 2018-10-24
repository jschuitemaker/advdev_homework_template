#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student

# recreate the routes to make sure that GREEN is active
oc delete route mlbparks -n ${GUID}-parks-prod
oc delete route nationalparks -n ${GUID}-parks-prod
oc delete route parksmap -n ${GUID}-parks-prod
oc expose service nationalparks-green --name=nationalparks -n ${GUID}-parks-prod
oc expose service mlbparks-green --name=mlbparks -n ${GUID}-parks-prod
oc expose service parksmap-green --name=parksmap -n ${GUID}-parks-prod
