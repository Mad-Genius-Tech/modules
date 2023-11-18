#!/bin/bash
set -e

ECS_TASK_DEFINITION=$1
REGION=$2

if [[ -z $AWS_PROFILE ]]; then 
  IMAGE_NAME=`AWS_PROFILE=$AWS_PROFILE aws ecs describe-task-definition --region ${REGION} --task-definition ${ECS_TASK_DEFINITION} | jq -re '.taskDefinition.containerDefinitions[0].image'`
else
  IMAGE_NAME=`aws ecs describe-task-definition --region ${REGION} --task-definition ${ECS_TASK_DEFINITION} | jq -re '.taskDefinition.containerDefinitions[0].image'`
fi

jq -n --arg IMAGE_NAME "$IMAGE_NAME" '{"IMAGE_NAME":$IMAGE_NAME}'

exit 0