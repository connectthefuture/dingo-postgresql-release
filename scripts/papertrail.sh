#!/bin/bash

# Displays all the logs for a specific CF service instance
# https://papertrailapp.com/groups/688143/events?q=(a65aebfc-3e73-419b-b50c-bdc0110136a1+OR+8e8f0540-8719-4d2a-9f2a-ffc02cb892dd)&r=604849041863630862-604849149376266257

BASE_PAPERTRAIL=${BASE_PAPERTRAIL:-https://papertrailapp.com/groups/688143}
ETCD_CLUSTER=${ETCD_CLUSTER:-10.244.4.2:4001}

service_name=$1
if [[ -z $service_name ]]; then
  echo "USAGE: papertrail.sh <service-name>"
  exit 1
fi

if [[ ! -f ~/.cf/config.json ]]; then
  echo "Login to target Cloud Foundry first"
  exit 1
fi

space_guid=$(cat ~/.cf/config.json | jq -r .SpaceFields.Guid)
if [[ -z $space_guid ]]; then
  echo "Target org/space first"
  exit 1
fi

service_guid=$(cf curl "/v2/spaces/${space_guid}/service_instances?q=name:${service_name}" | jq -r ".resources[0].metadata.guid")

any_guids=${service_guid}
backend_instance_guids=$(curl -s ${ETCD_CLUSTER}/v2/keys/serviceinstances/${service_guid}/nodes | jq -r ".node.nodes[].key")
for backend_guid in ${backend_instance_guids[@]}; do
  any_guids="${any_guids}+OR+${backend_guid}"
done

echo "${BASE_PAPERTRAIL}/events?q=(${any_guids})"
