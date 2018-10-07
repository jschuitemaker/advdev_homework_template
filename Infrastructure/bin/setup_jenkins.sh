#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# switch to the right project first 
oc project ${GUID}-jenkins

# create app from template, this will create everything we need
oc new-app -f ./Infrastructure/templates/jenkins.yaml -p GUID=${GUID}

# wait for it to be completed, the imagestreams are not always there (even though oc says it is created)
echo 'wait for imagestream to become ready..'
sleep 20

# the slave pod isn't being build after the bc is created... don't know why - start manually.. :-/
oc start-build jenkins-slave-appdev

# wait for it to be completed
while : ; do
    oc get pod -n ${GUID}-jenkins | grep 'slave' | grep "Completed"
    if [ $? == "0" ]
      then
        echo 'jenkins-slave-appdev build completed'
        break
      else
        echo 'jenkins-slave-appdev building sleep 10'
        sleep 10
    fi
done

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student
