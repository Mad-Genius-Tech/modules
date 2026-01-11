#!/bin/bash
set -e

ECS_TASK_DEFINITION=$1
REGION=$2
APP_NAME=$3

if [[ ! -z $AWS_PROFILE ]]; then
  PROFILE_NAME="--profile $AWS_PROFILE"
else
  PROFILE_NAME=""
fi

if [[ -z $APP_NAME ]]; then
  aws ecs describe-task-definition --region ${REGION} --task-definition ${ECS_TASK_DEFINITION} ${PROFILE_NAME} | \
  jq -r '.taskDefinition.containerDefinitions as $containers |
     if ($containers | length) == 1 then
        {"IMAGE_NAME": $containers[0].image}
     else
        $containers | 
        map({(.name): .image}) |
        add
     end'
else
  aws ecs describe-task-definition --region ${REGION} --task-definition ${ECS_TASK_DEFINITION} ${PROFILE_NAME} | jq -re --arg name "$APP_NAME" '.taskDefinition.containerDefinitions[] | select(.name == $name) | {"IMAGE_NAME": .image}'
fi


exit 0
