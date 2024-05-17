#!/bin/bash

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
AWS_REGION=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`
AUTOSCALING_GROUP_NAME=$(aws autoscaling describe-auto-scaling-instances --instance-ids $INSTANCE_ID --query 'AutoScalingInstances[*].AutoScalingGroupName' --region $AWS_REGION --output text)

STATUS=$(curl -s http://127.0.0.1/status?json)
ACTIVE=$(echo "$STATUS" | jq -r '."active processes"')
IDLE=$(echo "$STATUS" | jq -r '."idle processes"')
MAX_CHILDREN_REACHED=$(echo "$STATUS" | jq -r '."max children reached"')
SLOW_REQUESTS=$(echo "$STATUS" | jq -r '."slow requests"')
MAX_ACTIVE_PROCESSES=$(echo "$STATUS" | jq -r '."max active processes"')
echo "[INFO] ACTIVE=$ACTIVE IDLE=$IDLE MAX_CHILDREN_REACHED=$MAX_CHILDREN_REACHED SLOW_REQUESTS=$SLOW_REQUESTS MAX_ACTIVE_PROCESSES=$MAX_ACTIVE_PROCESSES"

aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "ActiveProcesses" --value "$ACTIVE" --unit Count --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME
aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "IdleProcesses" --value "$IDLE" --unit Count --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME
aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "MaxChildrenReached" --value "$MAX_CHILDREN_REACHED" --unit Count --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME
aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "SlowRequests" --value "$SLOW_REQUESTS" --unit Count --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME
aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "MaxActiveProcesses" --value "$MAX_ACTIVE_PROCESSES" --unit Count --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME

TOTAL_TIME=`curl -o /dev/null -s -w '%%{time_total}' https://${domain_name}`
echo "[INFO] TOTAL_TIME=$TOTAL_TIME"
aws cloudwatch put-metric-data --region $AWS_REGION --namespace "PHP-FPM" --metric-name "CurlTotalTime" --value "$TOTAL_TIME" --unit Seconds --dimensions InstanceId=$INSTANCE_ID,AutoScalingGroupName=$AUTOSCALING_GROUP_NAME
