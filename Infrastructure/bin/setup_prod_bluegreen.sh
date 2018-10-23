#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 GUID blue|${COLOR}"
    exit 1
fi

GUID=$1
COLOR=$2
echo "Setting up ${COLOR} Parks Production Environment in project ${GUID}-parks-prod"



# Set up a MongoDB database in the production project
# TODO 

# MLBPARKS--------------

# Create deployment configurations
# here we use the initial imagestream mlbparks:0.0 from the DEVELOPMENT project
oc new-app ${GUID}-parks-dev/mlbparks:0.0 --name=mlbparks-${COLOR} --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

# remove triggers to prevent automatic deployment when there is a new dev image
oc set triggers dc/mlbparks-${COLOR} --remove-all -n ${GUID}-parks-prod

# Configure the applications using ConfigMaps.
cat ./Infrastructure/environments/MongoDB-prod.env  <(echo) ./Infrastructure/environments/MLBParks-${COLOR}-prod.env > ./MLBParks-${COLOR}-prod.map
oc create configmap mlbparks-${COLOR}-config --from-env-file=./MLBParks-${COLOR}-prod.map -n ${GUID}-parks-prod
oc set env dc/mlbparks-${COLOR} --from=configmap/mlbparks-${COLOR}-config -n ${GUID}-parks-prod

oc set probe dc/mlbparks-${COLOR} --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-prod
oc set probe dc/mlbparks-${COLOR} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod

# this will create the services
oc expose dc/mlbparks-${COLOR} --port 8080 -n ${GUID}-parks-prod

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/mlbparks-${COLOR}  -n ${GUID}-parks-prod --post -c mlbparks --failure-policy=abort -- curl http://$(oc get route mlbparks-${COLOR} -n ${GUID}-parks-prod -o jsonpath='{ .spec.host }')/ws/data/load/

