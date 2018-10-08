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


# Create two OpenShift projects for development (including test) and production.

# To conserve resources, you need to test on the development images of the application, rather than setting up a separate test/QA project.

# Set up the correct permissions for the production project to deploy images from the development project.

# Set up a replicated MongoDB database (StatefulSet) with at least three replicas in the production project.

# Create build configurations in the development project.
# TODO - Will need to change the imagestream name back to jboss-eap70-openshift:1.7
oc new-build --binary=true --name="mlbparks" wildfly-120-centos7 -n ${GUID}-parks-dev

# Create deployment configurations in both the development and production projects.
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

# Configure the applications using ConfigMaps.
oc create configmap mlbparks-config --from-env-file=./Infrastructure/environments/MLBParks-dev.env -n ${GUID}-parks-dev
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev
oc set probe dc/mlbparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/mlbparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

# this will create the services
oc expose dc/mlbparks --port 8080 -n ${GUID}-parks-dev

# expose the above service as a route and mark it as type 'parksmap-backend' so the UI can discover this service
oc expose svc/mlbparks --labels=type=parksmap-backend 

# The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook)
# once the Pod is running.
oc set deployment-hook dc/mlbparks  -n ${GUID}-parks-dev --post -c mlbparks --failure-policy=abort -- curl http://$(oc get route mlbparks -n ${GUID}-parks-dev -o jsonpath='{ .spec.host }')/ws/data/load/