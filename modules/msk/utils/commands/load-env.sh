#!/usr/bin/env bash

# IAM ACCESS
# bash and zsh have different way to get the script name when using source
# we try the bash way with BASH_SOURCE and fallback on $0 which works for zsh
SCRIPT_DIR=$( dirname -- "$( readlink -f -- "${BASH_SOURCE[0]:-$0}"; )"; )
export CLASSPATH="${SCRIPT_DIR}/../client-configs/aws-msk-iam-auth-1.1.8-all.jar"
export COMMAND_CONFIG_PATH="utils/client-configs/iam.properties"
export AWS_PROFILE="${1}"
export BOOTSTRAP_SERVERS="${2}"