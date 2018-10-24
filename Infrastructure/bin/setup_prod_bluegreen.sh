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
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks-${COLOR} --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

# remove triggers to prevent automatic deployment when there is a new dev image
oc set triggers dc/mlbparks-${COLOR} --remove-all -n ${GUID}-parks-prod

# Configure the applications using ConfigMaps.
cat ./Infrastructure/environments/MongoDB-prod.env  <(echo) ./Infrastructure/environments/MLBParks-${COLOR}-prod.env > ./MLBParks-tmp-prod.map
oc create configmap mlbparks-${COLOR}-config --from-env-file=./MLBParks-tmp-prod.map -n ${GUID}-parks-prod
oc set env dc/mlbparks-${COLOR} --from=configmap/mlbparks-${COLOR}-config -n ${GUID}-parks-prod

oc set probe dc/mlbparks-${COLOR} --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-prod
oc set probe dc/mlbparks-${COLOR} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod

# this will create the services
oc expose dc/mlbparks-${COLOR} --port 8080 -n ${GUID}-parks-prod

# expose the green service as a route 
if [ $COLOR = 'green' ]
then
    oc expose service mlbparks-green --labels=type=parksmap-backend --name=mlbparks -n ${GUID}-parks-prod
fi

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/mlbparks-${COLOR}  -n ${GUID}-parks-prod --post -c mlbparks-${COLOR} --failure-policy=abort -- curl http://$(oc get route mlbparks -n ${GUID}-parks-prod -o jsonpath='{ .spec.host }')/ws/data/load/

# NATIONALPARKS--------------

# Create deployment configurations in both the development and production projects.
# here we use the initial imagestream mlbparks:0.0 from the DEVELOPMENT project
oc new-app ${GUID}-parks-dev/nationalparks:0.0-0 --name=nationalparks-${COLOR} --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

# remove triggers to prevent automatic deployment when there is a new dev image
oc set triggers dc/nationalparks-${COLOR} --remove-all -n ${GUID}-parks-prod

# Configure the applications using ConfigMaps.
cat ./Infrastructure/environments/MongoDB-prod.env  <(echo) ./Infrastructure/environments/Nationalparks-${COLOR}-prod.env > ./Nationalparks-tmp-prod.map
oc create configmap nationalparks-${COLOR}-config --from-env-file=./Nationalparks-tmp-prod.map -n ${GUID}-parks-prod
oc set env dc/nationalparks-${COLOR} --from=configmap/nationalparks-${COLOR}-config -n ${GUID}-parks-prod
oc set probe dc/nationalparks-${COLOR} --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-prod
oc set probe dc/nationalparks-${COLOR} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod

# this will create the services
oc expose dc/nationalparks-${COLOR} --port 8080 -n ${GUID}-parks-prod


# expose the green service as a route 
if [ $COLOR = 'green' ]
then
    oc expose service nationalparks-green --labels=type=parksmap-backend --name=nationalparks -n ${GUID}-parks-prod
fi

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/nationalparks-${COLOR} -n ${GUID}-parks-prod --post -c nationalparks-${COLOR} --failure-policy=abort -- curl http://$(oc get route nationalparks -n ${GUID}-parks-prod -o jsonpath='{ .spec.host }')/ws/data/load/

# PARKSMAP --------------

# Create deployment configurations in both the development and production projects.
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --name=parksmap-${COLOR} --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

# remove triggers to prevent automatic deployment when there is a new dev image
oc set triggers dc/parksmap-${COLOR} --remove-all -n ${GUID}-parks-prod

# Configure the applications using ConfigMaps.
cat ./Infrastructure/environments/MongoDB-prod.env  <(echo) ./Infrastructure/environments/ParksMap-${COLOR}-prod.env > ./ParksMap-tmp-prod.map
oc create configmap parksmap-${COLOR}-config --from-env-file=./ParksMap-tmp-prod.map -n ${GUID}-parks-prod
oc set env dc/parksmap-${COLOR} --from=configmap/parksmap-${COLOR}-config -n ${GUID}-parks-prod
oc set probe dc/parksmap-${COLOR} --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-prod
oc set probe dc/parksmap-${COLOR} --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-prod

# this will create the services
oc expose dc/parksmap-${COLOR} --port 8080 -n ${GUID}-parks-prod

# expose the green service as a route 
if [ $COLOR = 'green' ]
then
    oc expose service parksmap-green --name=parksmap -n ${GUID}-parks-prod
fi
