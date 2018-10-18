#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Set up the correct permissions for Jenkins to manipulate objects in the development and production projects.
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n  ${GUID}-parks-dev

# Set up a MongoDB database in the development project. (see README in MLBPARKS)
oc new-app -e MONGODB_USER=mongodb -e MONGODB_PASSWORD=mongodb -e MONGODB_DATABASE=parks -e MONGODB_ADMIN_PASSWORD=mongodb --name=mongodb registry.access.redhat.com/rhscl/mongodb-34-rhel7:latest -n ${GUID}-parks-dev

# MLBPARKS--------------
# Create build configurations in the development project.
# TODO - Will need to change the imagestream name back to jboss-eap70-openshift:1.7
    oc new-build --binary=true --name="mlbparks" wildfly -n ${GUID}-parks-dev

# Create deployment configurations in both the development and production projects.
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# Configure the applications using ConfigMaps.
#cat ./Infrastructure/environments/MongoDB-dev.env  <(echo) ./Infrastructure/environments/MLBParks-dev.env > ./MLBParks-dev.map
oc create configmap mlbparks-config --from-env-file=./Infrastructure/environments/MongoDB-dev.env -n ${GUID}-parks-dev
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev
oc set env dc/mlbparks APPNAME="MLB Parks (Dev)"
oc set probe dc/mlbparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/mlbparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# this will create the services
oc expose dc/mlbparks --port 8080 -n ${GUID}-parks-dev

# expose the above service as a route and mark it as type 'parksmap-backend' so the UI can discover this service
oc expose svc/mlbparks --labels=type=parksmap-backend -n ${GUID}-parks-dev

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/mlbparks  -n ${GUID}-parks-dev --post -c mlbparks --failure-policy=abort -- curl http://$(oc get route mlbparks -n ${GUID}-parks-dev -o jsonpath='{ .spec.host }')/ws/data/load/

# NATIONALPARKS--------------
# Create build configurations in the development project.
# TODO - Will need to change the imagestream name back to redhat-openjdk18-openshift:1.2
oc new-build --binary=true --name="nationalparks" openjdk18-openshift:latest -n ${GUID}-parks-dev

# Create deployment configurations in both the development and production projects.
oc new-app ${GUID}-parks-dev/nationalparks:0.0-0 --name=nationalparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# Configure the applications using ConfigMaps.
#cat ./Infrastructure/environments/MongoDB-dev.env  <(echo) ./Infrastructure/environments/Nationalparks-dev.env > ./Nationalparks-dev.map
oc create configmap nationalparks-config --from-env-file./Infrastructure/environments/MongoDB-dev.env -n ${GUID}-parks-dev
oc set env dc/nationalparks --from=configmap/nationalparks-config -n ${GUID}-parks-dev
oc set env dc/nationalparks APPNAME="National Parks (Dev)"
oc set probe dc/nationalparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/nationalparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# this will create the services
oc expose dc/nationalparks --port 8080 -n ${GUID}-parks-dev

# expose the above service as a route and mark it as type 'parksmap-backend' so the UI can discover this service
oc expose svc/nationalparks --labels=type=parksmap-backend -n ${GUID}-parks-dev

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/nationalparks -n ${GUID}-parks-dev --post -c nationalparks --failure-policy=abort -- curl http://$(oc get route nationalparks -n ${GUID}-parks-dev -o jsonpath='{ .spec.host }')/ws/data/load/


# PARKSMAP --------------
# Create build configurations in the development project.
# TODO - Will need to change the imagestream name back to redhat-openjdk18-openshift:1.2
oc new-build --binary=true --name="parksmap" openjdk18-openshift:latest -n ${GUID}-parks-dev

# Create deployment configurations in both the development and production projects.
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --name=parksmap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# Configure the applications using ConfigMaps.
#cat ./Infrastructure/environments/MongoDB-dev.env  <(echo) ./Infrastructure/environments/ParksMap-dev.env > ./ParksMap-dev.map
#oc create configmap parksmap-config --from-env-file=./ParksMap-dev.map -n ${GUID}-parks-dev

#oc set env dc/parksmap --from=configmap/parksmap-config -n ${GUID}-parks-dev
oc set env dc/mlbparks APPNAME="ParksMap (Dev)"
oc set probe dc/parksmap --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/parksmap --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# this will create the services
oc expose dc/parksmap --port 8080 -n ${GUID}-parks-dev

# expose the above service as a route and mark it as type 'parksmap-backend' so the UI can discover this service
oc expose svc/parksmap -n ${GUID}-parks-dev

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
#oc set deployment-hook dc/parksmap -n ${GUID}-parks-dev --post -c parksmap --failure-policy=abort -- curl http://$(oc get route parksmap -n ${GUID}-parks-dev -o jsonpath='{ .spec.host }')/ws/data/load/