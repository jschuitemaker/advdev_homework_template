#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# IMPORTANT: Switching to a project can lead to creating resources in other projects because of parallel pipelines.. yikes. 
# Use -n flag for all oc commands

# create app from template, this will create everything we need
oc new-app -f ./Infrastructure/templates/nexus.yaml -p GUID=${GUID} -n ${GUID}-nexus

# wait till deployment pod is done and nexus is running. 
# note: -l app=nexus3 |grep -v deploy is probably too much because the deploy pod is not labeled 'nexus3'. -l app=nexus3 should do the trick

while : ; do
  echo "Checking if Nexus is Ready..."
  oc get pod -n b60e-nexus -l app=nexus3 |grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

# setup nexus: would like to do this using a Hook but couldn't find how 
curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
chmod +x setup_nexus3.sh
sh setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${GUID}-nexus )
rm -f setup_nexus3.sh


# this will set the default URL on the openshift console to point to the Nexus console instead of the registry
oc annotate route nexus3 console.alpha.openshift.io/overview-app-route=true -n ${GUID}-nexus
oc annotate route nexus-registry console.alpha.openshift.io/overview-app-route=false -n ${GUID}-nexus


